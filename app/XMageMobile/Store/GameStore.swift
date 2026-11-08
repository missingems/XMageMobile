import Foundation
import Observation

@Observable
final class GameStore {
    private(set) var phase: ConnectionPhase = .idle
    private(set) var xmageVersion: String?
    private(set) var username: String?
    private(set) var decks: [String] = []
    private(set) var game: GameState?
    private(set) var prompt: Prompt?
    private(set) var waitingText: String?
    private(set) var log: [LogLine] = []
    private(set) var banner: String?
    private(set) var matchup: (deck: String, opponent: String)?
    private(set) var tables: [OnlineTable] = []
    private(set) var hasLoadedTables = false
    private(set) var rating: Int?
    private(set) var waitingTable: OnlineTable?
    private(set) var isTableOwner = false
    private(set) var isSeating = false
    private(set) var allowsComputer = true
    private(set) var deckTypes: [String] = []
    private(set) var isOnlineMatch = false
    var result: GameResult?
    private(set) var sideboarding: SideboardSession?
    private(set) var isSubmittingDeck = false
    private(set) var sideboardMessage: String?
    private(set) var isAwaitingNextGame = false
    private var pendingResult: GameResult?
    private var pendingResultTask: Task<Void, Never>?

    var matchSheet: MatchSheet? {
        get {
            if let sideboarding { return .sideboard(sideboarding) }
            if isAwaitingNextGame { return .waitingForNextGame }
            return result.map(MatchSheet.result)
        }
        set {
            if newValue == nil { result = nil }
        }
    }
    var lobbyAlert: String?

    var showsLobbyAlert: Bool {
        get { lobbyAlert != nil }
        set { if !newValue { lobbyAlert = nil } }
    }
    var presentedPrompt: Prompt?
    var lastError: String?

    private var connection: (any BridgeTransport)?
    private var listener: Task<Void, Never>?
    private var bannerTask: Task<Void, Never>?
    private var outgoing: Task<Void, Never>?
    private var pendingLogin: ServerSettings?
    private var lastDecks: (deck: String?, opponent: String?)?

    var isInGame: Bool { game != nil || phase == .playing || (phase == .startingGame && lastDecks != nil) }

    func connect(_ settings: ServerSettings) {
        disconnect()
        let connection: any BridgeTransport
        if settings.usesMacBridge {
            guard let url = settings.bridgeURL else {
                phase = .failed("That bridge address isn't valid.")
                return
            }
            connection = BridgeConnection(url: url)
        } else {
            guard let samples = Bundle.main.url(forResource: "sample-decks", withExtension: nil) else {
                phase = .failed("The sample decks are missing from this build.")
                return
            }
            let folders = [Bundle.main.url(forResource: "decks", withExtension: nil), samples].compactMap { $0 }
            connection = EmbeddedBridge(decksPath: folders.map { $0.path(percentEncoded: false) }.joined(separator: ":"))
        }
        phase = .reachingBridge
        pendingLogin = settings
        self.connection = connection
        listener = Task { [weak self] in
            for await event in connection.events() {
                self?.handle(event)
            }
        }
    }

    func disconnect() {
        listener?.cancel()
        listener = nil
        connection?.close()
        connection = nil
        resetGame()
        resetLobby()
        phase = .idle
    }

    func startGame(deck: String?, opponentDeck: String?) {
        leaveTable()
        isOnlineMatch = false
        lastDecks = (deck, opponentDeck)
        resetGame()
        phase = .startingGame
        send(.startAIGame(deck: deck, opponentDeck: opponentDeck))
    }

    func rematch() {
        startGame(deck: lastDecks?.deck, opponentDeck: lastDecks?.opponent)
    }

    func leaveGame() {
        send(.leaveGame)
        resetGame()
        lastDecks = nil
        isOnlineMatch = false
        phase = connection == nil ? .idle : .lobby
        if connection != nil {
            send(.watchTables(true))
        }
    }

    func createTable(deck: String?, format: String?, name: String?, password: String?, bestOf: Int = 1, rated: Bool = false) {
        guard phase == .lobby else { return }
        isSeating = true
        send(.createTable(deck: deck, deckType: format, name: name, password: password, bestOf: bestOf, rated: rated))
    }

    func submitSideboard(main: [DeckCard], sideboard: [DeckCard]) {
        guard sideboarding != nil, !isSubmittingDeck else { return }
        isSubmittingDeck = true
        sideboardMessage = nil
        send(.submitDeck(main: main, sideboard: sideboard))
    }

    func joinTable(_ table: OnlineTable, deck: String?, password: String?) {
        guard phase == .lobby else { return }
        isSeating = true
        send(.joinTable(id: table.id, deck: deck, password: password))
    }

    func leaveTable() {
        guard waitingTable != nil || isSeating else { return }
        send(.leaveTable)
        waitingTable = nil
        isTableOwner = false
        isSeating = false
    }

    func concede() {
        send(.playerAction(.concede))
    }

    func perform(_ action: PlayerAction) {
        send(.playerAction(action))
        if prompt?.kind == .select {
            prompt = nil
        }
    }

    func activate(_ card: Card) {
        guard card.isActionable, prompt != nil else { return }
        respond(.respondUUID(card.id))
    }

    func activateId(_ id: String) {
        guard prompt != nil else { return }
        respond(.respondUUID(id))
    }

    func choosePlayer(_ player: Player) {
        guard player.choosable, prompt != nil else { return }
        respond(.respondUUID(player.id))
    }

    func payMana(_ symbol: String) {
        guard let kind = prompt?.kind, kind == .mana || kind == .xmana else { return }
        respond(.respondManaType(symbol))
    }

    func done() {
        respond(.respondBoolean(false))
    }

    func answer(_ value: Bool) {
        respond(.respondBoolean(value))
    }

    func choose(_ choice: PromptChoice) {
        if prompt?.kind == .ability {
            respond(.respondUUID(choice.id))
        } else {
            respond(.respondString(choice.id))
        }
    }

    func chooseAmount(_ value: Int) {
        respond(.respondInteger(value))
    }

    func chooseAmounts(_ values: [Int]) {
        respond(.respondString(values.map(String.init).joined(separator: " ")))
    }

    func choosePile(_ first: Bool) {
        respond(.respondBoolean(first))
    }

    func special() {
        respond(.respondString("special"))
    }

    func reopenPrompt() {
        if let prompt, prompt.needsSheet {
            presentedPrompt = prompt
        }
    }

    private func respond(_ request: BridgeRequest) {
        prompt = nil
        presentedPrompt = nil
        send(request)
    }

    private func send(_ request: BridgeRequest) {
        guard let connection else { return }
        let previous = outgoing
        outgoing = Task {
            await previous?.value
            do {
                try await connection.send(request)
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    private func resetGame() {
        game = nil
        prompt = nil
        presentedPrompt = nil
        waitingText = nil
        log = []
        result = nil
        matchup = nil
        clearBetweenGames()
    }

    private func clearBetweenGames() {
        sideboarding = nil
        isSubmittingDeck = false
        sideboardMessage = nil
        isAwaitingNextGame = false
        pendingResult = nil
        pendingResultTask?.cancel()
        pendingResultTask = nil
    }

    private func resetLobby() {
        tables = []
        hasLoadedTables = false
        rating = nil
        waitingTable = nil
        isTableOwner = false
        isSeating = false
        isOnlineMatch = false
        allowsComputer = true
        deckTypes = []
    }

    private func handle(_ event: BridgeEvent) {
        switch event {
        case let .message(message):
            handle(message)
        case let .closed(reason):
            connection = nil
            listener = nil
            if phase == .reachingBridge {
                phase = .failed("Couldn't reach the bridge. \(reason ?? "")")
            } else if phase != .idle {
                phase = .failed("The bridge closed the connection.")
            }
        }
    }

    private func handle(_ message: BridgeMessage) {
        switch message {
        case let .hello(version, _, _):
            xmageVersion = version
            if let login = pendingLogin {
                phase = .loggingIn
                send(.connect(server: login.serverHost, port: login.serverPort, username: login.username))
            }
        case let .decks(names):
            decks = names
        case let .status(state, text, name, computer, types):
            switch state {
            case "connected":
                username = name
                allowsComputer = computer ?? true
                deckTypes = types
                phase = .lobby
                send(.watchTables(true))
            case "error":
                phase = .failed(text)
            case "disconnected" where phase.isConnected:
                phase = .failed(text)
            default:
                break
            }
        case let .tableReady(deck, opponent):
            matchup = (deck, opponent)
        case .gameStarted:
            if waitingTable != nil || isOnlineMatch {
                isOnlineMatch = true
                waitingTable = nil
                isSeating = false
                result = nil
                prompt = nil
                presentedPrompt = nil
                send(.watchTables(false))
            }
            clearBetweenGames()
            phase = .playing
        case let .tables(list, myRating):
            tables = list
            rating = myRating ?? rating
            hasLoadedTables = true
        case let .tableWaiting(table, owner):
            if isSeating || waitingTable != nil {
                waitingTable = table
                isTableOwner = owner
                isSeating = false
            }
        case let .tableClosed(text):
            if waitingTable != nil {
                waitingTable = nil
                isTableOwner = false
                lobbyAlert = text
            }
        case let .game(state):
            game = state
            if phase != .playing { phase = .playing }
        case let .prompt(next):
            prompt = next
            waitingText = nil
            presentedPrompt = next.needsSheet ? next : nil
        case let .waiting(text):
            waitingText = text.isEmpty ? nil : text
        case let .log(line):
            log.append(line)
            if log.count > 400 { log.removeFirst(log.count - 400) }
        case let .info(text):
            showBanner(text)
        case let .error(text):
            if isSeating || (phase == .lobby && !text.isEmpty) {
                isSeating = false
                lobbyAlert = text
            } else if phase == .startingGame || phase == .loggingIn {
                phase = .failed(text)
            } else {
                showBanner(text)
            }
        case let .gameOver(text):
            showBanner(text)
        case let .gameEnd(won, info, matchInfo):
            prompt = nil
            presentedPrompt = nil
            let matchContinues = isOnlineMatch && matchInfo.localizedStandardContains("need")
            let showsMatch = isOnlineMatch && !matchInfo.isEmpty
            let ended = GameResult(won: won, summary: showsMatch ? "\(info)\n\(matchInfo)" : info)
            if matchContinues {
                holdResultForSideboarding(ended)
            } else {
                result = ended
            }
        case let .sideboard(deck, seconds, main, sideboard):
            let previous = pendingResult ?? result
            pendingResultTask?.cancel()
            pendingResultTask = nil
            pendingResult = nil
            result = nil
            prompt = nil
            presentedPrompt = nil
            isAwaitingNextGame = false
            isSubmittingDeck = false
            sideboardMessage = nil
            sideboarding = SideboardSession(
                deckName: deck,
                main: main,
                sideboard: sideboard,
                deadline: .now.addingTimeInterval(TimeInterval(seconds)),
                previousGame: previous)
        case let .sideboardDone(automatic):
            guard sideboarding != nil else { break }
            sideboarding = nil
            isSubmittingDeck = false
            isAwaitingNextGame = true
            if automatic {
                showBanner("Time ran out, so your deck was locked in as it was.")
            }
        case let .sideboardRejected(text):
            isSubmittingDeck = false
            sideboardMessage = text
        case let .matchEnded(text):
            clearBetweenGames()
            result = GameResult(won: true, summary: text)
        case .unknown:
            break
        }
    }

    private func holdResultForSideboarding(_ ended: GameResult) {
        pendingResult = ended
        pendingResultTask?.cancel()
        pendingResultTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled, sideboarding == nil, let pendingResult else { return }
            result = pendingResult
            self.pendingResult = nil
        }
    }

    private func showBanner(_ text: String) {
        guard !text.isEmpty else { return }
        banner = text
        bannerTask?.cancel()
        bannerTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            banner = nil
        }
    }
}

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
    var result: GameResult?
    var presentedPrompt: Prompt?
    var lastError: String?

    private var connection: BridgeConnection?
    private var listener: Task<Void, Never>?
    private var bannerTask: Task<Void, Never>?
    private var outgoing: Task<Void, Never>?
    private var pendingLogin: ServerSettings?
    private var lastDecks: (deck: String?, opponent: String?)?

    var isInGame: Bool { game != nil || phase == .playing || (phase == .startingGame && lastDecks != nil) }

    func connect(_ settings: ServerSettings) {
        disconnect()
        guard let url = settings.bridgeURL else {
            phase = .failed("That bridge address isn't valid.")
            return
        }
        phase = .reachingBridge
        pendingLogin = settings
        let connection = BridgeConnection(url: url)
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
        phase = .idle
    }

    func startGame(deck: String?, opponentDeck: String?) {
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
        phase = connection == nil ? .idle : .lobby
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
    }

    private func handle(_ event: BridgeConnection.Event) {
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
        case let .status(state, text, name):
            switch state {
            case "connected":
                username = name
                phase = .lobby
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
            phase = .playing
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
            if phase == .startingGame || phase == .loggingIn {
                phase = .failed(text)
            } else {
                showBanner(text)
            }
        case let .gameOver(text):
            showBanner(text)
        case let .gameEnd(won, info):
            prompt = nil
            presentedPrompt = nil
            result = GameResult(won: won, summary: info)
        case .unknown:
            break
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

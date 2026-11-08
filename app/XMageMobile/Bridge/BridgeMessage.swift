import Foundation

nonisolated enum BridgeMessage: Sendable {
    case hello(xmageVersion: String, defaultServer: String, defaultPort: Int)
    case decks([String])
    case status(state: String, message: String, username: String?, allowsComputer: Bool?, deckTypes: [String])
    case tables([OnlineTable])
    case tableWaiting(OnlineTable, isOwner: Bool)
    case tableClosed(String)
    case tableReady(deck: String, opponentDeck: String)
    case gameStarted(gameId: String, playerId: String)
    case game(GameState)
    case prompt(Prompt)
    case waiting(String)
    case log(LogLine)
    case info(String)
    case error(String)
    case gameOver(String)
    case gameEnd(won: Bool, gameInfo: String, matchInfo: String)
    case sideboard(deck: String, seconds: Int, main: [DeckCard], sideboard: [DeckCard])
    case sideboardDone(automatic: Bool)
    case sideboardRejected(String)
    case matchEnded(String)
    case unknown(String)
}

extension BridgeMessage: Decodable {
    private enum Keys: String, CodingKey {
        case type, xmageVersion, defaultServer, defaultPort, names, state, message, username
        case deck, opponentDeck, gameId, playerId, prompt, text, won, gameInfo, matchInfo
        case allowsComputer, deckTypes, tables, table, isOwner
        case seconds, main, sideboard, automatic
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        let type = try c.decode(String.self, forKey: .type)
        func text(_ key: Keys) throws -> String { try c.decodeIfPresent(String.self, forKey: key) ?? "" }

        switch type {
        case "hello":
            self = .hello(
                xmageVersion: try text(.xmageVersion),
                defaultServer: try text(.defaultServer),
                defaultPort: try c.decodeIfPresent(Int.self, forKey: .defaultPort) ?? 17171)
        case "decks":
            self = .decks(try c.decodeIfPresent([String].self, forKey: .names) ?? [])
        case "status":
            self = .status(
                state: try text(.state),
                message: try text(.message),
                username: try c.decodeIfPresent(String.self, forKey: .username),
                allowsComputer: try c.decodeIfPresent(Bool.self, forKey: .allowsComputer),
                deckTypes: try c.decodeIfPresent([String].self, forKey: .deckTypes) ?? [])
        case "tables":
            self = .tables(try c.decodeIfPresent([OnlineTable].self, forKey: .tables) ?? [])
        case "tableWaiting":
            self = .tableWaiting(try c.decode(OnlineTable.self, forKey: .table), isOwner: try c.decodeIfPresent(Bool.self, forKey: .isOwner) ?? false)
        case "tableClosed":
            self = .tableClosed(try text(.text))
        case "tableReady":
            self = .tableReady(deck: try text(.deck), opponentDeck: try text(.opponentDeck))
        case "gameStarted":
            self = .gameStarted(gameId: try text(.gameId), playerId: try text(.playerId))
        case "game":
            self = .game(try c.decode(GameState.self, forKey: .state))
        case "prompt":
            self = .prompt(try c.decode(Prompt.self, forKey: .prompt))
        case "waiting":
            self = .waiting(try text(.text))
        case "log":
            self = .log(try LogLine(from: decoder))
        case "info":
            self = .info(try text(.text))
        case "error":
            self = .error(try text(.text))
        case "gameOver":
            self = .gameOver(try text(.text))
        case "gameEnd":
            self = .gameEnd(won: try c.decodeIfPresent(Bool.self, forKey: .won) ?? false, gameInfo: try text(.gameInfo), matchInfo: try text(.matchInfo))
        case "sideboard":
            self = .sideboard(
                deck: try text(.deck),
                seconds: try c.decodeIfPresent(Int.self, forKey: .seconds) ?? 180,
                main: try c.decodeIfPresent([DeckCard].self, forKey: .main) ?? [],
                sideboard: try c.decodeIfPresent([DeckCard].self, forKey: .sideboard) ?? [])
        case "sideboardDone":
            self = .sideboardDone(automatic: try c.decodeIfPresent(Bool.self, forKey: .automatic) ?? false)
        case "sideboardRejected":
            self = .sideboardRejected(try text(.text))
        case "matchEnded":
            self = .matchEnded(try text(.text))
        default:
            self = .unknown(type)
        }
    }
}

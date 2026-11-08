import Foundation

nonisolated enum BridgeRequest: Sendable {
    case connect(server: String, port: Int, username: String)
    case disconnect
    case startAIGame(deck: String?, opponentDeck: String?)
    case respondUUID(String)
    case respondBoolean(Bool)
    case respondInteger(Int)
    case respondString(String)
    case respondManaType(String)
    case playerAction(PlayerAction)
    case leaveGame
    case watchTables(Bool)
    case createTable(deck: String?, deckType: String?, name: String?, password: String?, bestOf: Int)
    case joinTable(id: String, deck: String?, password: String?)
    case leaveTable
    case submitDeck(main: [DeckCard], sideboard: [DeckCard])

    private var fields: [String: Any] {
        switch self {
        case let .connect(server, port, username):
            ["type": "connect", "server": server, "port": port, "username": username]
        case .disconnect:
            ["type": "disconnect"]
        case let .startAIGame(deck, opponentDeck):
            ["type": "startAIGame"].merging(
                [("deck", deck), ("opponentDeck", opponentDeck)].compactMap { key, value in value.map { (key, $0) } },
                uniquingKeysWith: { first, _ in first })
        case let .respondUUID(id):
            ["type": "respondUUID", "id": id]
        case let .respondBoolean(value):
            ["type": "respondBoolean", "value": value]
        case let .respondInteger(value):
            ["type": "respondInteger", "value": value]
        case let .respondString(value):
            ["type": "respondString", "value": value]
        case let .respondManaType(symbol):
            ["type": "respondManaType", "manaType": symbol]
        case let .playerAction(action):
            ["type": "playerAction", "action": action.rawValue]
        case .leaveGame:
            ["type": "leaveGame"]
        case let .watchTables(on):
            ["type": "watchTables", "on": on]
        case let .createTable(deck, deckType, name, password, bestOf):
            Self.compact(["type": "createTable", "deck": deck, "deckType": deckType, "name": name, "password": password])
                .merging(["bestOf": bestOf]) { _, new in new }
        case let .joinTable(id, deck, password):
            Self.compact(["type": "joinTable", "tableId": id, "deck": deck, "password": password])
        case .leaveTable:
            ["type": "leaveTable"]
        case let .submitDeck(main, sideboard):
            ["type": "submitDeck", "main": main.map(\.fields), "sideboard": sideboard.map(\.fields)]
        }
    }

    private static func compact(_ values: [String: String?]) -> [String: Any] {
        values.compactMapValues { $0 }
    }

    func encoded() throws -> String {
        let data = try JSONSerialization.data(withJSONObject: fields)
        return String(decoding: data, as: UTF8.self)
    }
}

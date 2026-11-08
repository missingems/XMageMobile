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
    case createTable(deck: String?, deckType: String?, name: String?, password: String?)
    case joinTable(id: String, deck: String?, password: String?)
    case leaveTable

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
        case let .createTable(deck, deckType, name, password):
            Self.compact(["type": "createTable", "deck": deck, "deckType": deckType, "name": name, "password": password])
        case let .joinTable(id, deck, password):
            Self.compact(["type": "joinTable", "tableId": id, "deck": deck, "password": password])
        case .leaveTable:
            ["type": "leaveTable"]
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

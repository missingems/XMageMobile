import Foundation

nonisolated struct GameState: Codable, Hashable, Sendable {
    var gameId: String?
    var turn: Int
    var phase: String?
    var step: String?
    var activePlayerId: String?
    var isPlayer: Bool
    var priorityPlayerId: String?
    var players: [Player]
    var hand: [Card]
    var stack: [Card]
    var combat: [CombatGroup]
    var revealed: [RevealedGroup]?

    var me: Player? { players.first(where: \.isYou) }
    var opponents: [Player] { players.filter { !$0.isYou } }
    var isMyTurn: Bool { me.map { $0.id == activePlayerId } ?? false }

    var attackerIds: Set<String> { Set(combat.flatMap(\.attackerIds)) }
    var blockerIds: Set<String> { Set(combat.flatMap(\.blockerIds)) }

    func card(withId id: String) -> Card? {
        if let card = hand.first(where: { $0.id == id }) { return card }
        if let card = stack.first(where: { $0.id == id }) { return card }
        for player in players {
            if let card = player.battlefield.first(where: { $0.id == id }) { return card }
        }
        return nil
    }

    func player(withId id: String?) -> Player? {
        players.first { $0.id == id }
    }
}

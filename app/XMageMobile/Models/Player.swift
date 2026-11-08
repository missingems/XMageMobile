import Foundation

nonisolated struct Player: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    var life: Int
    var libraryCount: Int
    var handCount: Int
    var isYou: Bool
    var isActive: Bool
    var hasPriority: Bool
    var hasLeft: Bool
    var isMonarch: Bool
    var choosable: Bool
    var manaPool: ManaPool
    var counters: [Counter]
    var battlefield: [Card]
    var graveyard: [Card]
    var exile: [Card]
    var command: [CommandObject]
    var companion: [Card]

    var lands: [Card] { battlefield.filter { $0.isLand && $0.attachedTo == nil } }
    var creatures: [Card] { battlefield.filter { !$0.isLand && $0.isCreature && $0.attachedTo == nil } }
    var otherPermanents: [Card] { battlefield.filter { !$0.isLand && !$0.isCreature && $0.attachedTo == nil } }

    func attachments(of card: Card) -> [Card] {
        battlefield.filter { $0.attachedTo == card.id }
    }
}

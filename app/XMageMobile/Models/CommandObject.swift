import Foundation

nonisolated struct CommandObject: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    var set: String?
    var number: String?
    var rules: [String] = []
    var playable = false
    var choosable = false

    var asCard: Card {
        var card = Card(id: id, name: name)
        card.set = set
        card.number = number
        card.rules = rules
        card.playable = playable
        card.choosable = choosable
        return card
    }
}

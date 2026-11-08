import Foundation

nonisolated struct LandGroup: Identifiable, Hashable {
    let cards: [Card]

    var id: String { cards[0].id }
    var representative: Card { cards.first(where: \.isActionable) ?? cards[0] }

    static func group(_ cards: [Card]) -> [LandGroup] {
        let lands = cards
        var order: [String] = []
        var buckets: [String: [Card]] = [:]
        for land in lands {
            let simple = land.isLand && land.counters.isEmpty && land.attachmentIds?.isEmpty != false && land.types == ["Land"]
            let key = simple ? "\(land.name)|\(land.isTapped)|\(land.isActionable)" : land.id
            if buckets[key] == nil { order.append(key) }
            buckets[key, default: []].append(land)
        }
        return order.compactMap { buckets[$0].map(LandGroup.init(cards:)) }
    }
}

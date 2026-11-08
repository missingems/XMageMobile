import Foundation

nonisolated struct RevealedGroup: Codable, Hashable, Sendable, Identifiable {
    enum Kind: String, Codable, Sendable {
        case revealed, lookedAt, hand
    }

    var kind: Kind
    var title: String
    var cards: [Card]

    var id: String { "\(kind.rawValue)·\(title)" }
    var signature: String { id + cards.map(\.id).joined(separator: ",") }

    var heading: String {
        switch kind {
        case .revealed: "Revealed · \(title)"
        case .lookedAt: "Looked At · \(title)"
        case .hand: "\(title)’s Hand"
        }
    }
}

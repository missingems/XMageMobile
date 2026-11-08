import Foundation

nonisolated struct DeckCard: Codable, Hashable, Sendable, Identifiable {
    let name: String
    let set: String
    let number: String
    var count: Int

    var id: String { "\(set)/\(number)/\(name)" }

    var fields: [String: Any] {
        ["name": name, "set": set, "number": number, "count": count]
    }
}

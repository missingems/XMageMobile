import Foundation

nonisolated struct OnlineSeat: Codable, Hashable, Sendable {
    let name: String
    let type: String?
    let rating: Int?

    var isOpen: Bool { name.isEmpty }
}

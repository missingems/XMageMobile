import Foundation

nonisolated struct OnlineSeat: Codable, Hashable, Sendable {
    let name: String
    let type: String?

    var isOpen: Bool { name.isEmpty }
}

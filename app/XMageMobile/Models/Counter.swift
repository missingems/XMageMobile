import Foundation

nonisolated struct Counter: Codable, Hashable, Sendable {
    let name: String
    let count: Int
}

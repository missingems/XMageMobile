import Foundation

nonisolated struct AmountRow: Codable, Hashable, Sendable {
    let label: String
    let min: Int
    let max: Int
    let value: Int
}

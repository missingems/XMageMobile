import Foundation

nonisolated struct GameResult: Identifiable, Hashable, Sendable {
    let id = UUID()
    let won: Bool
    let summary: String
}

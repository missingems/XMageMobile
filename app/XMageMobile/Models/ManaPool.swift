import Foundation

nonisolated struct ManaPool: Codable, Hashable, Sendable {
    var W = 0
    var U = 0
    var B = 0
    var R = 0
    var G = 0
    var C = 0

    var entries: [(symbol: String, count: Int)] {
        [("W", W), ("U", U), ("B", B), ("R", R), ("G", G), ("C", C)].filter { $0.count > 0 }
    }

    var isEmpty: Bool { entries.isEmpty }
}

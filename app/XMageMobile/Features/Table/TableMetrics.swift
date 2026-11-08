import Foundation

nonisolated struct TableMetrics: Equatable, Sendable {
    static let ratio = 88.0 / 63.0
    static let topBand = 84.0
    static let centerGap = 40.0
    static let margin = 16.0

    var size: CGSize
    var trailingInset: Double
    var isCompact: Bool
    var sideColumn: Double
    var actionColumn: Double
    var handCardWidth: Double
    var bottomBand: Double
    var creatureRowHeight: Double
    var landRowHeight: Double
    var creatureCardWidth: Double
    var landCardWidth: Double
    var focusedCardWidth: Double

    init(size: CGSize, trailingInset: Double = 0) {
        self.size = size
        self.trailingInset = trailingInset
        isCompact = size.width < 600
        sideColumn = isCompact ? 148 : 168
        let usesSideStrip = trailingInset >= 72 && size.height > size.width
        actionColumn = usesSideStrip ? 0 : (isCompact ? 128 : 176)
        handCardWidth = min(132, max(64, size.height * 0.12))
        bottomBand = max(112, handCardWidth * Self.ratio * 0.72)
        let half = max(0, size.height - Self.topBand - bottomBand - Self.centerGap) / 2
        creatureRowHeight = half * 0.58
        landRowHeight = half * 0.42
        creatureCardWidth = max(30, min(creatureRowHeight * 0.92 / Self.ratio, (size.width - 32) / 4.5, 150).rounded(.down))
        landCardWidth = max(26, min(landRowHeight * 0.9 / Self.ratio, creatureCardWidth * 0.8).rounded(.down))
        focusedCardWidth = min(260, max(170, size.height * 0.34), size.width * 0.6)
    }

    var usesSideStrip: Bool { actionColumn == 0 }
    var sideStripWidth: Double { max(0, trailingInset - 12) }
    var handFanWidth: Double { max(handCardWidth * 2, size.width - sideColumn - actionColumn) }
    var stackCardWidth: Double { max(58, min(110, creatureCardWidth * 1.1)) }
}

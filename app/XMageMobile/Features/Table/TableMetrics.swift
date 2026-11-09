import Foundation

nonisolated struct TableMetrics: Equatable, Sendable {
    static let ratio = 88.0 / 63.0
    static let hudHeight = 82.0
    static let topBand = hudHeight
    static let centerGap = 36.0
    static let margin = 16.0
    static let tableTilt = 24.0

    var size: CGSize
    var trailingInset: Double
    var leadingInset: Double
    var isCompact: Bool
    var isLandscape: Bool
    var actionColumn: Double
    var sideColumn: Double
    var fullWidth: Double
    var handCardWidth: Double
    var handBand: Double
    var topBand: Double
    var lifeRow: Double
    var centerGap: Double
    var creatureRowHeight: Double
    var landRowHeight: Double
    var creatureCardWidth: Double
    var landCardWidth: Double
    var focusedCardWidth: Double

    init(size: CGSize, leadingInset: Double = 0, trailingInset: Double = 0) {
        self.size = size
        self.leadingInset = leadingInset
        self.trailingInset = trailingInset
        isLandscape = size.width > size.height
        isCompact = isLandscape ? size.height < 560 : size.width < 600
        let tileRatio = 1 / CardCrop.aspectRatio
        fullWidth = size.width + leadingInset + trailingInset
        if isLandscape {
            actionColumn = isCompact ? 124 : 168
            sideColumn = max(trailingInset + actionColumn + Self.margin, leadingInset + Self.margin)
            handCardWidth = min(124, max(64, size.height * 0.16))
            handBand = (handCardWidth * Self.ratio * 0.66).rounded()
            topBand = isCompact ? 52 : 64
            lifeRow = isCompact ? 10 : 16
            centerGap = isCompact ? 28 : 36
            let half = max(0, size.height - topBand - lifeRow - handBand - centerGap - 12) / 2
            creatureRowHeight = half * 0.6
            landRowHeight = half * 0.4
            let fieldWidth = fullWidth - sideColumn * 2
            creatureCardWidth = max(40, min(creatureRowHeight * 1.0 / tileRatio, fieldWidth / 5.6, 150).rounded(.down))
            landCardWidth = max(34, min(landRowHeight * 0.98 / tileRatio, creatureCardWidth * 0.82).rounded(.down))
        } else {
            let usesSideStrip = trailingInset >= 72
            actionColumn = usesSideStrip ? 0 : (isCompact ? 128 : 176)
            sideColumn = actionColumn
            handCardWidth = min(132, max(64, size.height * 0.12))
            handBand = (handCardWidth * Self.ratio * 0.66).rounded()
            topBand = Self.hudHeight
            lifeRow = Self.hudHeight
            centerGap = Self.centerGap
            let half = max(0, size.height - Self.hudHeight * 2 - handBand - Self.centerGap) / 2
            creatureRowHeight = half * 0.58
            landRowHeight = half * 0.42
            creatureCardWidth = max(40, min(creatureRowHeight * 0.8 / tileRatio, (size.width - 32) / 3.6, 150).rounded(.down))
            landCardWidth = max(34, min(landRowHeight * 0.78 / tileRatio, creatureCardWidth * 0.8).rounded(.down))
        }
        focusedCardWidth = min(260, max(170, size.height * (isLandscape ? 0.5 : 0.34)), size.width * 0.6)
    }

    var usesSideStrip: Bool { actionColumn == 0 }
    static let pilesWidth = (38.0 + 6) * 3 + 16
    var sideStripWidth: Double { max(0, trailingInset - 12) }
    var bottomBand: Double { lifeRow + handBand }
    var handFanWidth: Double {
        if isLandscape {
            let side = max(sideColumn, trailingInset + Self.pilesWidth + Self.margin * 1.5)
            return max(handCardWidth * 2, fullWidth - side * 2)
        }
        return max(handCardWidth * 2, size.width - actionColumn - Self.margin)
    }
    var stackCardWidth: Double { max(58, min(110, isLandscape ? (size.height * 0.2) : creatureCardWidth * 1.1)) }
}

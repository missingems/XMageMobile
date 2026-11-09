import SwiftUI

struct ZonePiles: View {
    let player: Player
    var isMirrored = false
    let onShowZone: (TableZone) -> Void

    static let cardWidth = 38.0

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isMirrored { otherZones }
            if isMirrored { graveyard }
            library
            if !isMirrored { graveyard }
            if !isMirrored { otherZones }
        }
        .fixedSize()
    }

    private var graveyard: some View {
        pile("Graveyard", player.graveyard.count, zone: .graveyard, actionable: actionable(in: player.graveyard)) {
            topCard(actionable(in: player.graveyard) ?? player.graveyard.last)
        }
    }

    @ViewBuilder
    private var otherZones: some View {
        if !player.exile.isEmpty {
            let usable = actionable(in: player.exile)
            pile("Exile", player.exile.count, zone: .exile, actionable: usable) {
                topCard(usable ?? player.exile.last)
                    .saturation(usable == nil ? 0 : 1)
            }
        }
        if !player.command.isEmpty {
            let commandCards = player.command.map(\.asCard)
            let usable = actionable(in: commandCards)
            pile("Command zone", player.command.count, zone: .command, actionable: usable) {
                topCard(usable ?? commandCards.first)
            }
        }
        if !player.companion.isEmpty {
            pile("Companion", player.companion.count, zone: .companion, actionable: actionable(in: player.companion)) {
                topCard(player.companion.first)
            }
        }
    }

    private var library: some View {
        pile("Library", player.libraryCount, zone: nil) {
            CardBack(width: Self.cardWidth)
        }
    }

    private func actionable(in cards: [Card]) -> Card? {
        cards.last(where: \.choosable) ?? cards.last(where: \.playable)
    }

    @ViewBuilder
    private func pile<Thumbnail: View>(_ label: String, _ count: Int, zone: TableZone?, actionable: Card? = nil, @ViewBuilder thumbnail: () -> Thumbnail) -> some View {
        let glow: Color? = actionable.map { $0.choosable ? .yellow : CardTile.playableEdge }
        let radius = CardFrameStyle.cornerRadius(forWidth: Self.cardWidth) + 1
        let content = thumbnail()
            .frame(width: Self.cardWidth, height: Self.cardWidth * TableMetrics.ratio)
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(glow ?? .white.opacity(0.18), lineWidth: glow == nil ? 0.5 : 2)
            }
            .shadow(color: (glow ?? .black).opacity(glow == nil ? 0.4 : 0.7), radius: glow == nil ? 2 : 6, y: 1)
            .overlay(alignment: .bottom) {
                Text(count, format: .number)
                    .font(.caption2.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(glow ?? .white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(.black.opacity(0.75), in: .capsule)
                    .offset(y: 7)
            }
            .padding(.horizontal, 3)
            .padding(.bottom, 7)
            .contentShape(.rect)
        let description = actionable == nil ? "\(label), \(count) cards" : "\(label), \(count) cards, has cards you can use"

        if let zone {
            Button { onShowZone(zone) } label: { content }
                .buttonStyle(.plain)
                .accessibilityLabel(description)
        } else {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(description)
        }
    }

    @ViewBuilder
    private func topCard(_ card: Card?) -> some View {
        if let card {
            CardArt(card: card, width: Self.cardWidth)
        } else {
            RoundedRectangle(cornerRadius: CardFrameStyle.cornerRadius(forWidth: Self.cardWidth))
                .fill(.white.opacity(0.04))
                .strokeBorder(.white.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
    }
}

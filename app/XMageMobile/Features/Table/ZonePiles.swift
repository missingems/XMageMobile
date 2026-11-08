import SwiftUI

struct ZonePiles: View {
    let player: Player
    let onShowZone: (TableZone) -> Void

    private let cardWidth = 16.0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(player.name)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    pile("Library", player.libraryCount, zone: nil) {
                        CardBack(width: cardWidth)
                    }
                    pile("Graveyard", player.graveyard.count, zone: .graveyard, actionable: actionable(in: player.graveyard)) {
                        topCard(actionable(in: player.graveyard) ?? player.graveyard.last)
                    }
                }
                if !player.exile.isEmpty || !player.command.isEmpty || !player.companion.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
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
                }
            }
        }
        .fixedSize()
    }

    private func actionable(in cards: [Card]) -> Card? {
        cards.last(where: \.choosable) ?? cards.last(where: \.playable)
    }

    @ViewBuilder
    private func pile<Thumbnail: View>(_ label: String, _ count: Int, zone: TableZone?, actionable: Card? = nil, @ViewBuilder thumbnail: () -> Thumbnail) -> some View {
        let glow: Color? = actionable.map { $0.choosable ? .yellow : CardTile.playableEdge }
        let content = HStack(spacing: 5) {
            thumbnail()
                .frame(width: cardWidth, height: cardWidth * TableMetrics.ratio)
            Text(count, format: .number)
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(glow ?? .secondary)
        }
        .background {
            if let glow {
                Capsule()
                    .fill(glow.opacity(0.18))
                    .strokeBorder(glow, lineWidth: 1.5)
                    .padding(-4)
                    .shadow(color: glow.opacity(0.6), radius: 6)
            }
        }
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
            CardArt(card: card, width: cardWidth)
        } else {
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
        }
    }
}

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
                    pile("Graveyard", player.graveyard.count, zone: .graveyard) {
                        topCard(player.graveyard.last)
                    }
                }
                if !player.exile.isEmpty || !player.command.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        if !player.exile.isEmpty {
                            pile("Exile", player.exile.count, zone: .exile) {
                                topCard(player.exile.last)
                                    .saturation(0)
                            }
                        }
                        if !player.command.isEmpty {
                            pile("Command zone", player.command.count, zone: .command) {
                                topCard(player.command.first?.asCard)
                            }
                        }
                    }
                }
            }
        }
        .fixedSize()
    }

    @ViewBuilder
    private func pile<Thumbnail: View>(_ label: String, _ count: Int, zone: TableZone?, @ViewBuilder thumbnail: () -> Thumbnail) -> some View {
        let content = HStack(spacing: 5) {
            thumbnail()
                .frame(width: cardWidth, height: cardWidth * TableMetrics.ratio)
            Text(count, format: .number)
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }

        if let zone {
            Button { onShowZone(zone) } label: { content }
                .buttonStyle(.plain)
                .accessibilityLabel("\(label), \(count) cards")
        } else {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(label), \(count) cards")
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

import SwiftUI

struct StackColumn: View {
    let cards: [Card]
    let width: Double
    var motion: Namespace.ID?
    let onTap: (Card) -> Void
    let onInspect: (Card) -> Void

    var body: some View {
        let shown = Array(cards.prefix(5).reversed())
        VStack(spacing: 8) {
            Text("Stack")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            if cards.count > shown.count {
                Text("\(cards.count - shown.count) more below")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: -width * TableMetrics.ratio * 0.66) {
                ForEach(shown) { card in
                    CardTile(card: card, width: width, showsTapped: false)
                        .cardMotion(card.id, in: motion)
                        .tableAnchor(card.id)
                        .onTapGesture { onTap(card) }
                        .contextMenu {
                            Button("Details", systemImage: "info.circle") { onInspect(card) }
                        } preview: {
                            CardArt(card: card, width: 260)
                        }
                }
            }
        }
        .padding(8)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}

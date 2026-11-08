import SwiftUI

struct SideboardCardRow: View {
    let card: DeckCard
    let movesToSideboard: Bool
    let onMove: () -> Void

    private var actionTitle: String {
        movesToSideboard ? "Move One to Sideboard" : "Move One to Main Deck"
    }

    var body: some View {
        Button(action: onMove) {
            HStack(spacing: 12) {
                Text(card.count, format: .number)
                    .font(.body.monospacedDigit().weight(.semibold))
                    .frame(minWidth: 20, alignment: .trailing)
                DeckCardImage(card: card, width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.name)
                        .lineLimit(1)
                    Text(card.set)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: movesToSideboard ? "arrow.down.circle" : "arrow.up.circle")
                    .font(.title3)
                    .foregroundStyle(.tint)
            }
            .contentShape(.rect)
        }
        .foregroundStyle(.primary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.count) \(card.name)")
        .accessibilityHint(actionTitle)
        .accessibilityAddTraits(.isButton)
        .contextMenu {
            Button(actionTitle, systemImage: movesToSideboard ? "arrow.down" : "arrow.up", action: onMove)
        } preview: {
            DeckCardImage(card: card, width: 260)
        }
    }
}

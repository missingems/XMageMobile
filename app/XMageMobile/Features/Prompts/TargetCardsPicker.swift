import SwiftUI

struct TargetCardsPicker: View {
    let message: String
    let cards: [Card]
    let onChoose: (Card) -> Void

    @State private var inspected: Card?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(message).foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                    ForEach(orderedCards) { card in
                        CardTile(card: card, width: 100, showsTapped: false)
                            .opacity(card.choosable ? 1 : 0.45)
                            .onTapGesture {
                                if card.choosable { onChoose(card) } else { inspected = card }
                            }
                            .contextMenu {
                                Button("Details", systemImage: "info.circle") { inspected = card }
                            } preview: {
                                CardArt(card: card, width: 260)
                            }
                    }
                }
            }
            .padding()
        }
        .sheet(item: $inspected) { CardDetailView(card: $0) }
    }

    private var orderedCards: [Card] {
        cards.filter(\.choosable) + cards.filter { !$0.choosable }
    }
}

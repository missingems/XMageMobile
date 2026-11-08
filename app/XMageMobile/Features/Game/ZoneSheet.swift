import SwiftUI

struct ZoneSheet: View {
    let title: String
    let cards: [Card]
    var onTap: ((Card) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var inspected: Card?

    var body: some View {
        NavigationStack {
            ScrollView {
                if cards.isEmpty {
                    ContentUnavailableView("Empty", systemImage: "tray", description: Text("There are no cards here."))
                        .padding(.top, 60)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 12)], spacing: 12) {
                        ForEach(cards) { card in
                            CardTile(card: card, width: 104, showsTapped: false)
                                .onTapGesture {
                                    if card.isActionable, let onTap {
                                        dismiss()
                                        onTap(card)
                                    } else {
                                        inspected = card
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
            .sheet(item: $inspected) { card in
                CardDetailView(card: card)
            }
        }
        .presentationDetents([.medium, .large])
    }
}

import SwiftUI

struct PilePicker: View {
    let message: String
    let pile1: [Card]
    let pile2: [Card]
    let onChoose: (Bool) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(message).foregroundStyle(.secondary)
                pile("Pile 1", cards: pile1) { onChoose(true) }
                pile("Pile 2", cards: pile2) { onChoose(false) }
            }
            .padding()
        }
    }

    private func pile(_ title: String, cards: [Card], action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Button("Choose \(title)", action: action)
                    .buttonStyle(.glassProminent)
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(cards) { card in
                        CardTile(card: card, width: 86, showsTapped: false)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

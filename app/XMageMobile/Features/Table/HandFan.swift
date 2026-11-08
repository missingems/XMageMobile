import SwiftUI

struct HandFan: View {
    let cards: [Card]
    let cardWidth: Double
    let availableWidth: Double
    let focusedId: String?
    var motion: Namespace.ID?
    let onTap: (Card) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let count = cards.count
        let middle = Double(count - 1) / 2
        let tilt = count > 1 ? min(5, 26 / Double(count)) : 0
        let swing = cardWidth * TableMetrics.ratio * sin(tilt * middle * .pi / 180)
        let usable = max(0, availableWidth - cardWidth - 2 * swing - 16)
        let step = count > 1 ? min(cardWidth * 0.8, usable / Double(count - 1)) : 0

        ZStack {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                let distance = Double(index) - middle
                Button {
                    onTap(card)
                } label: {
                    CardTile(card: card, width: cardWidth, showsTapped: false)
                        .cardMotion(card.id, in: motion)
                }
                .buttonStyle(HandCardButtonStyle(isRaised: card.isActionable))
                .rotationEffect(.degrees(distance * tilt), anchor: .bottom)
                .offset(x: distance * step, y: distance * distance * 1.4)
                .opacity(card.id == focusedId ? 0 : 1)
                .zIndex(Double(index))
                .accessibilityHint("Shows the card larger")
            }
        }
        .frame(width: availableWidth, height: cardWidth * TableMetrics.ratio)
        .animation(reduceMotion ? nil : .snappy, value: cards.map(\.id))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Your hand, \(count) cards")
    }
}

private struct HandCardButtonStyle: ButtonStyle {
    let isRaised: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: isRaised ? -10 : 0)
            .scaleEffect(configuration.isPressed ? 1.04 : 1, anchor: .bottom)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

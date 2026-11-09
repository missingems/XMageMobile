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
        let minimumStep = cardWidth * 0.5
        let usable = max(0, availableWidth - cardWidth - 24)
        let overflows = count > 1 && usable / Double(count - 1) < minimumStep
        Group {
            if overflows {
                scrollingHand(step: minimumStep)
            } else {
                fan
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: cards.map(\.id))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Your hand, \(count) cards")
    }

    private var fan: some View {
        let count = cards.count
        let middle = Double(count - 1) / 2
        let tilt = count > 1 ? min(5, 26 / Double(count)) : 0
        let swing = cardWidth * TableMetrics.ratio * sin(tilt * middle * .pi / 180)
        let usable = max(0, availableWidth - cardWidth - 2 * swing - 16)
        let step = count > 1 ? min(cardWidth * 0.8, usable / Double(count - 1)) : 0
        return ZStack {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                let distance = Double(index) - middle
                cardButton(card)
                    .rotationEffect(.degrees(distance * tilt), anchor: .bottom)
                    .offset(x: distance * step, y: distance * distance * 1.4)
                    .zIndex(Double(index))
            }
        }
        .frame(width: availableWidth, height: cardWidth * TableMetrics.ratio)
    }

    private func scrollingHand(step: Double) -> some View {
        let viewport = availableWidth
        let unit = cardWidth
        let edge = cardWidth * 0.5
        return ScrollView(.horizontal) {
            HStack(spacing: step - cardWidth) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    cardButton(card)
                        .zIndex(Double(index))
                        .visualEffect { content, proxy in
                            let distance = (proxy.frame(in: .scrollView).midX - viewport / 2) / unit
                            return content
                                .rotationEffect(.degrees(distance * 4.5), anchor: .bottom)
                                .offset(y: distance * distance * 3)
                        }
                }
            }
            .padding(.horizontal, edge)
            .padding(.top, 14)
        }
        .scrollIndicators(.hidden)
        .defaultScrollAnchor(.center)
        .mask {
            LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.07),
                                   .init(color: .black, location: 0.93), .init(color: .clear, location: 1)],
                           startPoint: .leading, endPoint: .trailing)
        }
        .frame(width: availableWidth, height: cardWidth * TableMetrics.ratio + 14)
    }

    private func cardButton(_ card: Card) -> some View {
        Button {
            onTap(card)
        } label: {
            CardTile(card: card, width: cardWidth, showsTapped: false)
                .cardMotion(card.id, in: motion)
        }
        .buttonStyle(HandCardButtonStyle(isRaised: card.isActionable))
        .opacity(card.id == focusedId ? 0 : 1)
        .accessibilityHint("Shows the card larger")
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

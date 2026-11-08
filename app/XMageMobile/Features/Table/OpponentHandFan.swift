import SwiftUI

struct OpponentHandFan: View {
    let count: Int

    private let cardWidth = 30.0

    var body: some View {
        let shown = min(count, 12)
        let middle = Double(shown - 1) / 2
        let step = cardWidth * 0.62
        ZStack {
            ForEach(0..<shown, id: \.self) { index in
                let distance = Double(index) - middle
                CardBack(width: cardWidth)
                    .rotationEffect(.degrees(180))
                    .overlay {
                        RoundedRectangle(cornerRadius: CardFrameStyle.cornerRadius(forWidth: cardWidth))
                            .strokeBorder(.black.opacity(0.6), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                    .rotationEffect(.degrees(-distance * 6), anchor: .top)
                    .offset(x: distance * step, y: -distance * distance * 0.8)
            }
        }
        .frame(width: max(cardWidth, Double(max(shown - 1, 0)) * step + cardWidth + 16),
               height: cardWidth * TableMetrics.ratio)
        .overlay(alignment: .bottom) {
            if count > 0 {
                Text(count, format: .number)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .glassEffect(.regular, in: .capsule)
                    .offset(y: 10)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Opponent’s hand, \(count) cards")
    }
}

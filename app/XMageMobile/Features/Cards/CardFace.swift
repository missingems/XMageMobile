import SwiftUI

struct CardFace: View {
    let card: Card
    let width: Double

    var body: some View {
        let scale = width / 100
        VStack(alignment: .leading, spacing: 3 * scale) {
            HStack(alignment: .top, spacing: 2 * scale) {
                Text(card.name)
                    .font(.system(size: 8.5 * scale, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                ManaCostView(cost: card.manaCost, size: 8 * scale)
            }
            if let typeLine = card.typeLine, !typeLine.isEmpty {
                Text(typeLine)
                    .font(.system(size: 6.5 * scale, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .opacity(0.8)
            }
            if width > 70 {
                Text(card.rules.joined(separator: "\n"))
                    .font(.system(size: 6 * scale))
                    .lineLimit(Int(6 * scale))
                    .minimumScaleFactor(0.6)
                    .padding(3 * scale)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(.white.opacity(0.55), in: .rect(cornerRadius: 3 * scale))
            } else {
                Spacer(minLength: 0)
            }
            if card.showsPowerToughness, let power = card.power, let toughness = card.toughness {
                HStack {
                    Spacer()
                    Text("\(power)/\(toughness)")
                        .font(.system(size: 9 * scale, weight: .bold, design: .rounded))
                }
            }
        }
        .foregroundStyle(.black.opacity(0.88))
        .padding(5 * scale)
        .frame(width: width, height: width / CardFrameStyle.aspectRatio, alignment: .topLeading)
        .background(CardFrameStyle.gradient(for: card))
    }
}

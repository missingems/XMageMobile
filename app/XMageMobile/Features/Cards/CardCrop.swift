import SwiftUI

struct CardCrop: View {
    let card: Card
    let width: Double

    static let aspectRatio = 0.76

    @State private var image: UIImage?

    private var height: Double { width / Self.aspectRatio }

    static func cornerRadius(forWidth width: Double) -> Double {
        width * 0.06
    }

    var body: some View {
        let radius = Self.cornerRadius(forWidth: width)
        let border = max(1.5, width * 0.03)
        let barHeight = max(10, width * 0.17)
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(CardFrameStyle.edge(for: card))
            VStack(spacing: 0) {
                nameBar(height: barHeight)
                Color.clear
                    .overlay { art }
                    .clipped()
                    .overlay(alignment: .bottom) { footer }
            }
            .frame(width: width - border * 2, height: height - border * 2)
            .clipShape(.rect(cornerRadius: max(1, radius - border)))
        }
        .frame(width: width, height: height)
        .task(id: imageKey) {
            guard !card.faceDown, !card.isAbility else { return }
            let loaded = await CardImageLoader.shared.image(set: card.set, number: card.number, name: card.name, variant: .artCrop)
            if let loaded {
                withAnimation(.easeOut(duration: 0.2)) { image = loaded }
            }
        }
    }

    private func nameBar(height: Double) -> some View {
        Text(card.faceDown ? "" : card.name)
            .font(.cardTitle(fixedSize: max(7, height * 0.62)))
            .foregroundStyle(.black.opacity(0.85))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, height * 0.35)
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .leading)
            .background(CardFrameStyle.bar(for: card))
            .overlay(alignment: .bottom) {
                Rectangle().fill(.black.opacity(0.45)).frame(height: 0.5)
            }
    }

    @ViewBuilder
    private var footer: some View {
        let keywords = Keyword.parse(card.rules)
        let stat = statText
        if !keywords.isEmpty || stat != nil {
            let size = max(12, width * 0.21)
            HStack(alignment: .bottom, spacing: size * 0.2) {
                ForEach(keywords.prefix(3), id: \.self) { keyword in
                    Image(systemName: keyword.systemImage)
                        .font(.system(size: size * 0.5, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: size, height: size)
                        .background(.black.opacity(0.8), in: .circle)
                        .overlay { Circle().stroke(.white.opacity(0.4), lineWidth: 0.6) }
                        .accessibilityLabel(keyword.title)
                }
                Spacer(minLength: 0)
                if let stat {
                    Text(stat)
                        .font(.system(size: size * 0.72, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .fixedSize()
                        .foregroundStyle((card.damage ?? 0) > 0 ? Color(red: 1, green: 0.5, blue: 0.45) : .white)
                        .padding(.horizontal, size * 0.3)
                        .frame(minWidth: size * 1.8, minHeight: size)
                        .background(.black.opacity(0.85), in: .rect(cornerRadius: size * 0.22))
                        .overlay { RoundedRectangle(cornerRadius: size * 0.22).stroke(CardFrameStyle.bar(for: card), lineWidth: 1) }
                }
            }
            .padding(size * 0.18)
            .background(alignment: .bottom) {
                LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                    .frame(height: size * 1.6)
            }
        }
    }

    private var statText: String? {
        if card.showsPowerToughness, let power = card.power, let toughness = card.toughness {
            if let damage = card.damage, damage > 0, let value = Int(toughness) {
                return "\(power)/\(value - damage)"
            }
            return "\(power)/\(toughness)"
        }
        return card.loyalty ?? card.defense
    }

    @ViewBuilder
    private var art: some View {
        if card.faceDown {
            CardBack(width: width)
        } else if let image {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFill()
        } else {
            CardFrameStyle.gradient(for: card)
        }
    }

    private var imageKey: String {
        "\(card.set ?? "")/\(card.number ?? "")/\(card.name)"
    }
}

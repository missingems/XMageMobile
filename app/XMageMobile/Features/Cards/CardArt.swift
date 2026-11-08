import SwiftUI

struct CardArt: View {
    let card: Card
    let width: Double

    @State private var image: UIImage?

    var body: some View {
        Group {
            if card.faceDown {
                CardBack(width: width)
            } else if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(CardFrameStyle.aspectRatio, contentMode: .fill)
                    .frame(width: width, height: width / CardFrameStyle.aspectRatio)
            } else {
                CardFace(card: card, width: width)
            }
        }
        .clipShape(.rect(cornerRadius: CardFrameStyle.cornerRadius(forWidth: width)))
        .task(id: imageKey) {
            guard !card.faceDown, !card.isAbility else { return }
            let loaded = await CardImageLoader.shared.image(set: card.set, number: card.number, name: card.name)
            if let loaded {
                withAnimation(.easeOut(duration: 0.2)) { image = loaded }
            }
        }
    }

    private var imageKey: String {
        "\(card.set ?? "")/\(card.number ?? "")/\(card.name)"
    }
}

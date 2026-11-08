import SwiftUI

struct DeckCardImage: View {
    let card: DeckCard
    let width: Double

    @State private var image: UIImage?

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: width * 0.05, style: .continuous)
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                shape.fill(.fill.tertiary)
            }
        }
        .frame(width: width, height: width * 1.396)
        .clipShape(shape)
        .accessibilityHidden(true)
        .task(id: card.id) {
            image = await CardImageLoader.shared.image(set: card.set, number: card.number, name: card.name)
        }
    }
}

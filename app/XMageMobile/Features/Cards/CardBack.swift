import SwiftUI

struct CardBack: View {
    let width: Double

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(CardFrameStyle.aspectRatio, contentMode: .fill)
            } else {
                placeholder
            }
        }
        .frame(width: width, height: width / CardFrameStyle.aspectRatio)
        .clipShape(.rect(cornerRadius: CardFrameStyle.cornerRadius(forWidth: width)))
        .task {
            guard image == nil else { return }
            image = await CardImageLoader.shared.cardBack()
        }
        .accessibilityLabel("Face-down card")
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: CardFrameStyle.cornerRadius(forWidth: width))
            .fill(Color(red: 0.24, green: 0.17, blue: 0.11).gradient)
    }
}

import SwiftUI

enum CardFrameStyle {
    static let aspectRatio = 63.0 / 88.0

    static func cornerRadius(forWidth width: Double) -> Double {
        width * 0.055
    }

    static func gradient(for card: Card) -> LinearGradient {
        let tones: [Color] = if card.isLand {
            [Color(red: 0.62, green: 0.55, blue: 0.45), Color(red: 0.45, green: 0.40, blue: 0.33)]
        } else if card.colors.count > 1 {
            [Color(red: 0.86, green: 0.74, blue: 0.42), Color(red: 0.70, green: 0.56, blue: 0.28)]
        } else if let color = card.colors.first, let tone = ManaSymbol.color(for: color) {
            [tone, tone.mix(with: .black, by: 0.25)]
        } else {
            [Color(red: 0.74, green: 0.74, blue: 0.76), Color(red: 0.55, green: 0.56, blue: 0.60)]
        }
        return LinearGradient(colors: tones, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

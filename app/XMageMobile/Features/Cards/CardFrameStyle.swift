import SwiftUI

enum CardFrameStyle {
    static let aspectRatio = 63.0 / 88.0

    private static let basics = ["Plains": "W", "Island": "U", "Swamp": "B", "Mountain": "R", "Forest": "G"]
    private static let gold = Color(red: 0.86, green: 0.70, blue: 0.36)
    private static let landTone = Color(red: 0.62, green: 0.55, blue: 0.45)
    private static let artifactTone = Color(red: 0.62, green: 0.64, blue: 0.68)

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

    static func bar(for card: Card) -> LinearGradient {
        let base: Color
        if card.isLand {
            base = basics[card.name].map(ManaIdentity.color) ?? landTone
        } else if card.colors.count > 1 {
            base = gold
        } else if let color = card.colors.first {
            base = ManaIdentity.color(color)
        } else {
            base = artifactTone
        }
        return LinearGradient(colors: [base.mix(with: .white, by: 0.55), base.mix(with: .white, by: 0.3)],
                              startPoint: .top, endPoint: .bottom)
    }

    static func edge(for card: Card) -> LinearGradient {
        let tones: [Color]
        if card.isLand {
            let base = basics[card.name].map(ManaIdentity.color) ?? landTone
            tones = [base.mix(with: .white, by: 0.2), base.mix(with: .black, by: 0.3)]
        } else if card.colors.count == 2 {
            tones = card.colors.map { ManaIdentity.color($0).mix(with: .white, by: 0.15) }
        } else if card.colors.count > 2 {
            tones = [gold.mix(with: .white, by: 0.2), gold.mix(with: .black, by: 0.25)]
        } else if let color = card.colors.first {
            let base = ManaIdentity.color(color)
            tones = [base.mix(with: .white, by: 0.25), base.mix(with: .black, by: 0.2)]
        } else {
            tones = [artifactTone.mix(with: .white, by: 0.2), artifactTone.mix(with: .black, by: 0.3)]
        }
        return LinearGradient(colors: tones, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

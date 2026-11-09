import SwiftUI

struct CardBadges: View {
    let card: Card
    let combatRole: CombatRole?
    let count: Int
    let scale: Double
    var isProminent = false

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 2) {
                if let combatRole {
                    badge(combatRole.systemImage, tint: combatRole.tint)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                if count > 1 {
                    pill("×\(count)", tint: .black.opacity(0.75))
                }
                ForEach(card.counters, id: \.name) { counter in
                    pill("\(counter.count) \(Self.shortName(counter.name))", tint: .purple)
                }
                Spacer(minLength: 0)
                if !isProminent, let stat = statText {
                    pill(stat, tint: isDamaged ? .red : .black.opacity(0.78))
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(3 * scale)
        .padding(.top, isProminent ? 12 * scale : 0)
        .allowsHitTesting(false)
    }

    private var isDamaged: Bool { (card.damage ?? 0) > 0 }

    private var statText: String? {
        if card.showsPowerToughness, let power = card.power, let toughness = card.toughness {
            let damage = card.damage ?? 0
            if damage > 0, let value = Int(toughness) {
                return "\(power)/\(value - damage)"
            }
            return "\(power)/\(toughness)"
        }
        if let loyalty = card.loyalty { return loyalty }
        if let defense = card.defense { return defense }
        return nil
    }

    private func pill(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: max(9, 10 * scale), weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 4 * scale)
            .padding(.vertical, 1.5 * scale)
            .background(tint, in: .capsule)
    }

    private func badge(_ systemImage: String, tint: Color) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: max(9, 10 * scale), weight: .bold))
            .foregroundStyle(.white)
            .padding(3 * scale)
            .background(tint, in: .circle)
    }

    static func shortName(_ name: String) -> String {
        switch name.lowercased() {
        case "p1p1", "+1/+1": "+1/+1"
        case "m1m1", "-1/-1": "−1/−1"
        default: name.count > 8 ? String(name.prefix(6)) + "…" : name
        }
    }
}

import SwiftUI

struct ManaSymbol: View {
    let symbol: String
    var size = 14.0

    var body: some View {
        Text(label)
            .font(.system(size: size * 0.62, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.black.opacity(0.85))
            .frame(width: size, height: size)
            .background(fill, in: .circle)
            .overlay { Circle().strokeBorder(.black.opacity(0.25), lineWidth: 0.5) }
            .accessibilityHidden(true)
    }

    private var label: String {
        switch symbol {
        case "T": "⤵"
        case "Q": "⤴"
        default: symbol.count > 2 ? String(symbol.prefix(1)) : symbol
        }
    }

    private var fill: AnyShapeStyle {
        let colors = symbol.split(separator: "/").compactMap { Self.color(for: String($0)) }
        if colors.count > 1 {
            return AnyShapeStyle(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        return AnyShapeStyle(colors.first ?? Self.generic)
    }

    static let generic = Color(red: 0.80, green: 0.78, blue: 0.75)

    static func color(for symbol: String) -> Color? {
        switch symbol {
        case "W": Color(red: 0.97, green: 0.95, blue: 0.82)
        case "U": Color(red: 0.62, green: 0.80, blue: 0.93)
        case "B": Color(red: 0.70, green: 0.66, blue: 0.64)
        case "R": Color(red: 0.94, green: 0.60, blue: 0.47)
        case "G": Color(red: 0.62, green: 0.79, blue: 0.58)
        case "C": Color(red: 0.84, green: 0.82, blue: 0.86)
        default: nil
        }
    }

    static func symbols(in cost: String?) -> [String] {
        guard let cost else { return [] }
        return cost.split(separator: "}").compactMap { part in
            guard let open = part.firstIndex(of: "{") else { return nil }
            return String(part[part.index(after: open)...])
        }
    }
}

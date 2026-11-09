import SwiftUI

struct PhaseRail: View {
    enum Side { case leading, trailing, all }

    let side: Side
    let current: GameStep?
    let isActive: Bool
    var length = 120.0
    var litColor = PhaseRail.lit

    private struct Marker: Hashable {
        let title: String
        let steps: Set<GameStep>
        let isMain: Bool
    }

    private static let leadingMarkers = [
        Marker(title: "Beginning", steps: [.UNTAP, .UPKEEP, .DRAW], isMain: false),
        Marker(title: "Main 1", steps: [.PRECOMBAT_MAIN], isMain: true),
    ]

    private static let trailingMarkers = [
        Marker(title: "Combat", steps: [.BEGIN_COMBAT, .DECLARE_ATTACKERS, .DECLARE_BLOCKERS, .FIRST_COMBAT_DAMAGE, .COMBAT_DAMAGE, .END_COMBAT], isMain: false),
        Marker(title: "Main 2", steps: [.POSTCOMBAT_MAIN], isMain: true),
        Marker(title: "End", steps: [.END_TURN, .CLEANUP], isMain: false),
    ]

    static let lit = Color(red: 1, green: 0.78, blue: 0.36)

    var body: some View {
        let markers = switch side {
        case .leading: Self.leadingMarkers
        case .trailing: Self.trailingMarkers
        case .all: Self.leadingMarkers + Self.trailingMarkers
        }
        let lineColors: [Color] = switch side {
        case .leading: [.clear, .white.opacity(0.35)]
        case .trailing: [.white.opacity(0.35), .clear]
        case .all: [.clear, .white.opacity(0.35), .clear]
        }
        ZStack {
            LinearGradient(colors: lineColors, startPoint: .leading, endPoint: .trailing)
                .frame(height: 1)
            HStack(spacing: 0) {
                if side != .trailing { Spacer(minLength: 0) }
                HStack(spacing: side == .all ? 12 : 18) {
                    ForEach(markers, id: \.self) { marker in
                        dot(marker)
                    }
                }
                .padding(.horizontal, side == .all ? 4 : 12)
                if side != .leading { Spacer(minLength: 0) }
            }
        }
        .frame(width: length, height: 20)
    }

    private func dot(_ marker: Marker) -> some View {
        let on = isActive && current.map(marker.steps.contains) == true
        let size = marker.isMain ? 10.0 : 7.0
        return Rectangle()
            .fill(on ? AnyShapeStyle(litColor) : AnyShapeStyle(Color(white: isActive ? 0.55 : 0.35)))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(45))
            .shadow(color: on ? litColor.opacity(0.9) : .clear, radius: 5)
            .scaleEffect(on ? 1.35 : 1)
            .animation(.snappy, value: on)
    }
}

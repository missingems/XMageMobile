import SwiftUI

struct PlayerAvatar: View {
    let player: Player
    let identity: [String]
    let onChoose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var change: LifeChange?

    private struct LifeChange: Equatable {
        let id = UUID()
        let delta: Int
    }

    private let diameter = 60.0

    var body: some View {
        Button(action: onChoose) {
            emblem
        }
        .buttonStyle(.plain)
        .allowsHitTesting(player.choosable)
        .accessibilityRemoveTraits(player.choosable ? [] : .isButton)
        .accessibilityLabel("\(player.name), \(player.life) life\(player.hasPriority ? ", has priority" : "")")
        .accessibilityHint(player.choosable ? "Choose as target" : "")
        .onChange(of: player.life) { old, new in
            withAnimation(reduceMotion ? nil : .snappy) {
                change = LifeChange(delta: new - old)
            }
        }
        .task(id: change?.id) {
            guard change != nil else { return }
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation(.easeOut(duration: 0.3)) { change = nil }
        }
    }

    private var emblem: some View {
        ZStack {
            Circle().fill(fill)
            Circle().fill(.black.opacity(0.3))
            Text(player.life, format: .number)
                .font(.system(size: 26, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: Double(player.life)))
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
        }
        .frame(width: diameter, height: diameter)
        .overlay {
            Circle().strokeBorder(ringColor, lineWidth: ringWidth)
        }
        .overlay {
            if player.hasPriority {
                Circle()
                    .strokeBorder(.white, lineWidth: 2)
                    .padding(-5)
            }
        }
        .overlay {
            if player.choosable {
                Circle()
                    .strokeBorder(.yellow, lineWidth: 3)
                    .padding(-6)
                    .phaseAnimator([0.35, 1.0]) { content, phase in
                        content.opacity(reduceMotion ? 1 : phase)
                    } animation: { _ in .easeInOut(duration: 0.7) }
            }
        }
        .overlay(alignment: .top) {
            if let change {
                Text(change.delta > 0 ? "+\(change.delta)" : "\(change.delta)")
                    .font(.system(size: 15, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(change.delta < 0 ? Color.red : Color.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .glassEffect(.regular, in: .capsule)
                    .offset(y: -14)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .tableAnchor(player.id)
    }

    private var ringColor: Color {
        if let change { return change.delta < 0 ? .red : .green }
        return player.life <= 5 ? .red : .white.opacity(0.25)
    }

    private var ringWidth: Double {
        change != nil || player.life <= 5 ? 3 : 1
    }

    private var fill: AnyShapeStyle {
        let colors = identity.map(ManaIdentity.color)
        switch colors.count {
        case 0: return AnyShapeStyle(ManaIdentity.color("").gradient)
        case 1: return AnyShapeStyle(colors[0].gradient)
        default: return AnyShapeStyle(AngularGradient(colors: colors + [colors[0]], center: .center))
        }
    }
}

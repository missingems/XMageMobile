import SwiftUI

struct LifePlate: View {
    let player: Player
    let state: GameState
    let identity: [String]
    var ribbonEdge = VerticalEdge.bottom
    let onChoose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var change: LifeChange?

    private struct LifeChange: Equatable {
        let id = UUID()
        let delta: Int
    }

    private var isActive: Bool { state.activePlayerId == player.id }

    var body: some View {
        Button(action: onChoose) { plate }
            .buttonStyle(.plain)
            .allowsHitTesting(player.choosable)
            .background(alignment: ribbonEdge == .bottom ? .top : .bottom) { ribbon }
            .padding(.bottom, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(player.name), \(player.life) life\(isActive ? ", active player" : "")\(player.hasPriority ? ", has priority" : "")")
        .accessibilityHint(player.choosable ? "Choose as target" : "")
        .accessibilityAddTraits(player.choosable ? .isButton : [])
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

    private var ribbon: some View {
        let colors = identity.isEmpty ? [ManaIdentity.color("")] : identity.map(ManaIdentity.color)
        let fill = LinearGradient(colors: colors.map { $0.mix(with: .black, by: 0.35) }, startPoint: .leading, endPoint: .trailing)
        return Text(player.name)
            .font(.cardTitle(size: 13, relativeTo: .caption2))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 14)
            .padding(ribbonEdge == .bottom ? .bottom : .top, 2)
            .frame(minWidth: 96, minHeight: 26, maxHeight: 26, alignment: ribbonEdge == .bottom ? .bottom : .top)
            .fixedSize()
            .background(fill, in: .rect(cornerRadius: 5))
            .overlay { RoundedRectangle(cornerRadius: 5).stroke(.white.opacity(0.3), lineWidth: 0.8) }
            .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
            .padding(ribbonEdge == .bottom ? .top : .bottom, 38)
            .accessibilityHidden(true)
    }

    private var plate: some View {
        let shape = ChamferedPlate(cut: 9)
        return Text(player.life, format: .number)
            .font(.system(size: 24, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .contentTransition(.numericText(value: Double(player.life)))
            .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
            .frame(width: 62, height: 44)
            .background {
                shape.fill(LinearGradient(colors: [Color(red: 0.27, green: 0.29, blue: 0.34), Color(red: 0.11, green: 0.12, blue: 0.15)],
                                          startPoint: .top, endPoint: .bottom))
            }
            .overlay {
                shape.strokeBorder(LinearGradient(colors: [ringColor, ringColor.mix(with: .black, by: 0.45)],
                                                  startPoint: .top, endPoint: .bottom), lineWidth: ringWidth)
            }
            .overlay {
                if player.hasPriority {
                    shape.inset(by: -4).stroke(.white.opacity(0.85), lineWidth: 1.5)
                }
            }
            .overlay {
                if player.choosable {
                    shape.inset(by: -6).stroke(.yellow, lineWidth: 3)
                        .phaseAnimator([0.35, 1.0]) { content, phase in
                            content.opacity(reduceMotion ? 1 : phase)
                        } animation: { _ in .easeInOut(duration: 0.7) }
                }
            }
            .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
            .overlay(alignment: .top) {
                if let change {
                    Text(change.delta > 0 ? "+\(change.delta)" : "\(change.delta)")
                        .font(.system(size: 15, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(change.delta < 0 ? Color.red : Color.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.8), in: .capsule)
                        .offset(y: -18)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .tableAnchor(player.id)
    }

    private var ringColor: Color {
        if let change { return change.delta < 0 ? .red : .green }
        if player.life <= 5 { return .red }
        return isActive ? PhaseRail.lit : Color(red: 0.72, green: 0.74, blue: 0.78)
    }

    private var ringWidth: Double {
        change != nil || player.life <= 5 || isActive ? 2.5 : 1.5
    }
}

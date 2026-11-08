import SwiftUI

struct PhaseTracker: View {
    enum Style { case full, strip }

    let state: GameState
    var style: Style = .full

    private var current: GameStep? {
        state.step.flatMap(GameStep.init(rawValue:))?.stripStep
    }

    private var turnColor: Color {
        state.isMyTurn ? .accentColor : .primary
    }

    var body: some View {
        Group {
            switch style {
            case .full:
                VStack(spacing: 6) {
                    Text(state.isMyTurn ? "Your Turn" : "Opponent’s Turn")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(turnColor)
                    HStack(spacing: 3) {
                        ForEach(GameStep.strip, id: \.self) { step in
                            Capsule()
                                .fill(step == current ? AnyShapeStyle(turnColor) : AnyShapeStyle(.quaternary))
                                .frame(width: step == current ? 14 : 5, height: 5)
                        }
                    }
                    Text([current?.title, "Turn \(state.turn)"].compactMap(\.self).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .strip:
                VStack(spacing: 2) {
                    Text(state.isMyTurn ? "Your Turn" : "Their Turn")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(turnColor)
                    if let current {
                        Text(current.title)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .multilineTextAlignment(.center)
            }
        }
        .lineLimit(2)
        .animation(.snappy, value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(state.isMyTurn ? "Your" : "Opponent’s") turn, turn \(state.turn), \(current?.title ?? "")")
    }
}

import SwiftUI

struct ActionCluster: View {
    @Environment(GameStore.self) private var store
    let state: GameState
    var isStrip = false
    var showsPhase = true

    private struct Action {
        var title: String
        var systemImage: String
        var isEnabled = true
        var perform: () -> Void = {}
    }

    var body: some View {
        VStack(spacing: isStrip ? 10 : 12) {
            if showsPhase {
                PhaseTracker(state: state, style: isStrip ? .strip : .full)
            }
            buttons
        }
    }

    private var buttons: some View {
        GlassEffectContainer(spacing: 8) {
            VStack(spacing: 8) {
                ForEach(Array(secondaryActions.enumerated()), id: \.offset) { _, action in
                    Button(action: action.perform) {
                        label(action, isPrimary: false)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .disabled(!action.isEnabled)
                }
                let primary = primaryAction
                Button(action: primary.perform) {
                    if store.prompt == nil {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel("Waiting for opponent")
                    } else {
                        label(primary, isPrimary: true)
                    }
                }
                .buttonStyle(.glassProminent)
                .controlSize(isStrip ? .large : .extraLarge)
                .disabled(!primary.isEnabled)
                .keyboardShortcut(.defaultAction)
            }
        }
        .animation(.snappy, value: store.prompt?.id)
    }

    @ViewBuilder
    private func label(_ action: Action, isPrimary: Bool) -> some View {
        if isStrip {
            VStack(spacing: 4) {
                Image(systemName: action.systemImage)
                    .font(.title3)
                Text(action.title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(action.title.contains(" ") ? 2 : 1)
                    .multilineTextAlignment(.center)
                    .allowsTightening(true)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        } else if !showsPhase && isPrimary {
            Label(action.title, systemImage: action.systemImage)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
        } else {
            Text(action.title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
        }
    }

    private var primaryAction: Action {
        guard let prompt = store.prompt else {
            return Action(title: "Waiting", systemImage: "hourglass", isEnabled: false)
        }
        let step = state.step.flatMap(GameStep.init(rawValue:))
        switch prompt.kind {
        case .select:
            if prompt.isPriority {
                return Action(title: state.stack.isEmpty ? "Pass" : "Resolve", systemImage: state.stack.isEmpty ? "arrow.forward" : "checkmark") { store.done() }
            }
            if step == .DECLARE_ATTACKERS, state.isMyTurn {
                let attacking = state.me?.creatures.contains { state.attackerIds.contains($0.id) } ?? false
                return Action(title: attacking ? "Attack" : "No Attacks", systemImage: attacking ? "bolt.fill" : "bolt.slash") { store.done() }
            }
            if step == .DECLARE_BLOCKERS, !state.isMyTurn {
                let blocking = state.me?.creatures.contains { state.blockerIds.contains($0.id) } ?? false
                return Action(title: blocking ? "Block" : "No Blocks", systemImage: blocking ? "shield.fill" : "shield.slash") { store.done() }
            }
            return Action(title: prompt.doneLabel ?? "Done", systemImage: "checkmark") { store.done() }
        case .target:
            if prompt.needsSheet {
                return Action(title: "Choose…", systemImage: "list.bullet") { store.reopenPrompt() }
            }
            if prompt.required != true {
                return Action(title: "Done", systemImage: "checkmark") { store.done() }
            }
            return Action(title: "Pick Target", systemImage: "scope", isEnabled: false)
        case .ask:
            return Action(title: prompt.yesLabel ?? "Yes", systemImage: "checkmark") { store.answer(true) }
        case .mana:
            return Action(title: "Pay Mana", systemImage: "drop.fill", isEnabled: false)
        case .xmana:
            return Action(title: "Done", systemImage: "checkmark") { store.answer(true) }
        case .choice, .ability, .amount, .multiAmount, .pile:
            return Action(title: "Choose…", systemImage: "list.bullet") { store.reopenPrompt() }
        case .unknown:
            return Action(title: "OK", systemImage: "checkmark") { store.done() }
        }
    }

    private var secondaryActions: [Action] {
        var actions: [Action] = []
        if let special = store.prompt?.specialLabel {
            actions.append(Action(title: special, systemImage: "star") { store.special() })
        }
        switch store.prompt?.kind {
        case .ask:
            actions.append(Action(title: store.prompt?.noLabel ?? "No", systemImage: "xmark") { store.answer(false) })
        case .mana:
            actions.append(Action(title: "Cancel", systemImage: "xmark") { store.done() })
        case .xmana:
            actions.append(Action(title: "Cancel", systemImage: "xmark") { store.answer(false) })
        case nil:
            actions.append(skipAction)
        case .select where store.prompt?.isPriority == true:
            actions.append(skipAction)
        default:
            break
        }
        return actions
    }

    private var skipAction: Action {
        state.isMyTurn
            ? Action(title: "End Turn", systemImage: "forward.end.fill") { store.perform(.passUntilNextTurn) }
            : Action(title: "To My Turn", systemImage: "forward.end.alt.fill") { store.perform(.passUntilMyNextTurn) }
    }
}

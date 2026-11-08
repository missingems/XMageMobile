#if DEBUG
import Foundation

struct Autopilot {
    let turns: Int
    let holdStep: String?
    private var attempted: Set<String> = []

    init(turns: Int, holdStep: String? = nil) {
        self.turns = turns
        self.holdStep = holdStep
    }

    mutating func respond(to prompt: Prompt, in store: GameStore) {
        guard let state = store.game else { return }
        if let holdStep {
            if state.turn >= turns, state.step == holdStep { return }
        } else if state.turn > turns {
            return
        }
        let me = state.me
        let step = state.step.flatMap(GameStep.init(rawValue:))
        switch prompt.kind {
        case .target:
            if prompt.message.localizedStandardContains("starting player"), let me {
                store.choosePlayer(me)
            } else if let id = prompt.targetIds?.first {
                store.activateId(id)
            } else {
                store.done()
            }
        case .ask:
            store.answer(!prompt.message.localizedStandardContains("mulligan"))
        case .select where !prompt.isPriority && (step == .DECLARE_ATTACKERS || step == .DECLARE_BLOCKERS):
            let pool = state.players.flatMap(\.battlefield).filter { $0.isCreature && $0.isActionable }
            if let card = pool.first(where: { !attempted.contains("combat-\(state.turn)-\($0.id)") }) {
                attempted.insert("combat-\(state.turn)-\(card.id)")
                store.activate(card)
            } else {
                store.done()
            }
        case .select:
            let candidates = state.hand.filter(\.playable).sorted { $0.isLand && !$1.isLand }
            if prompt.isPriority, state.isMyTurn, let card = candidates.first(where: { !attempted.contains($0.id) }) {
                attempted.insert(card.id)
                store.activate(card)
            } else {
                store.done()
            }
        case .mana, .xmana:
            if let land = me?.battlefield.first(where: { $0.playable && !attempted.contains("mana-\($0.id)") }) {
                attempted.insert("mana-\(land.id)")
                store.activate(land)
            } else {
                store.done()
            }
        case .choice, .ability:
            if let first = prompt.choices?.first { store.choose(first) } else { store.done() }
        case .amount:
            store.chooseAmount(prompt.min ?? 0)
        case .multiAmount:
            store.chooseAmounts((prompt.rows ?? []).map(\.value))
        case .pile:
            store.choosePile(true)
        case .unknown:
            store.done()
        }
    }
}
#endif

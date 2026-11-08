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

    static func sideboard(_ session: SideboardSession, swap: Bool) -> (main: [DeckCard], sideboard: [DeckCard]) {
        var main = session.main
        var side = session.sideboard
        guard swap, !main.isEmpty, !side.isEmpty else { return (main, side) }
        var out = main[0]
        var incoming = side[0]
        main[0].count -= 1
        side[0].count -= 1
        out.count = 1
        incoming.count = 1
        main.append(incoming)
        side.append(out)
        return (main.filter { $0.count > 0 }, side.filter { $0.count > 0 })
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

import SwiftUI

struct SideboardView: View {
    let session: SideboardSession

    @Environment(GameStore.self) private var store
    @State private var main: [DeckCard]
    @State private var side: [DeckCard]
    @State private var confirmsLeave = false

    private static let sideboardLimit = 15
    private static let autoSubmitLead: TimeInterval = 15

    init(session: SideboardSession) {
        self.session = session
        _main = State(initialValue: Self.sorted(session.main))
        _side = State(initialValue: Self.sorted(session.sideboard))
    }

    private var mainCount: Int { main.reduce(0) { $0 + $1.count } }
    private var sideCount: Int { side.reduce(0) { $0 + $1.count } }
    private var isChanged: Bool { main != Self.sorted(session.main) }

    private var problem: String? {
        if mainCount < session.mainCount {
            return "Your main deck needs at least \(session.mainCount) cards."
        }
        if sideCount > Self.sideboardLimit {
            return "Your sideboard can hold at most \(Self.sideboardLimit) cards."
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            List {
                if let previous = session.previousGame {
                    Section {
                        Label(previous.summary, systemImage: previous.won ? "trophy.fill" : "flag.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    ForEach(main) { card in
                        SideboardCardRow(card: card, movesToSideboard: true) {
                            move(card, toSideboard: true)
                        }
                    }
                } header: {
                    Text("Main Deck · \(mainCount)")
                }
                Section {
                    if side.isEmpty {
                        Text("This deck has no sideboard.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(side) { card in
                        SideboardCardRow(card: card, movesToSideboard: false) {
                            move(card, toSideboard: false)
                        }
                    }
                } header: {
                    Text("Sideboard · \(sideCount)")
                } footer: {
                    if let message = problem ?? store.sideboardMessage {
                        Text(message).foregroundStyle(.red)
                    } else {
                        Text("Tap a card to move one copy. Touch and hold to see it.")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Leave Match", systemImage: "xmark", role: .destructive) { confirmsLeave = true }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(session.deckName)
                            .font(.headline)
                            .lineLimit(1)
                        Text(timerInterval: Date.now...max(session.deadline, .now), countsDown: true)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if store.isSubmittingDeck {
                        ProgressView()
                    } else {
                        Button(isChanged ? "Ready" : "Keep Deck", role: .confirm, action: submit)
                            .disabled(problem != nil)
                    }
                }
            }
            .confirmationDialog("Leave this match?", isPresented: $confirmsLeave, titleVisibility: .visible) {
                Button("Leave Match", role: .destructive, action: store.leaveGame)
            } message: {
                Text("Your opponent wins the match.")
            }
        }
        .interactiveDismissDisabled()
        .task(id: session.id) {
            let wait = session.deadline.timeIntervalSinceNow - Self.autoSubmitLead
            if wait > 0 {
                try? await Task.sleep(for: .seconds(wait))
            }
            guard !Task.isCancelled, !store.isSubmittingDeck else { return }
            if problem == nil {
                submit()
            } else {
                store.submitSideboard(main: session.main, sideboard: session.sideboard)
            }
        }
    }

    private func submit() {
        store.submitSideboard(main: main, sideboard: side)
    }

    private func move(_ card: DeckCard, toSideboard: Bool) {
        var source = toSideboard ? main : side
        var target = toSideboard ? side : main
        guard let index = source.firstIndex(where: { $0.id == card.id }) else { return }
        source[index].count -= 1
        if source[index].count == 0 {
            source.remove(at: index)
        }
        if let existing = target.firstIndex(where: { $0.id == card.id }) {
            target[existing].count += 1
        } else {
            var moved = card
            moved.count = 1
            target = Self.sorted(target + [moved])
        }
        withAnimation {
            main = toSideboard ? source : target
            side = toSideboard ? target : source
        }
    }

    private static func sorted(_ cards: [DeckCard]) -> [DeckCard] {
        cards.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}

import SwiftUI

struct PromptSheet: View {
    let prompt: Prompt

    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Later", systemImage: "chevron.down") { dismiss() }
                    }
                    if prompt.required != true {
                        ToolbarItem(placement: .destructiveAction) {
                            Button("Skip") { store.done() }
                        }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
    }

    private var title: String {
        switch prompt.kind {
        case .ability: "Choose an Ability"
        case .amount, .multiAmount: "Choose an Amount"
        case .pile: "Choose a Pile"
        case .target: "Choose a Card"
        default: "Choose"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch prompt.kind {
        case .choice, .ability:
            ChoiceList(message: prompt.message, choices: prompt.choices ?? []) { store.choose($0) }
        case .amount:
            AmountPicker(message: prompt.message, range: (prompt.min ?? 0)...max(prompt.min ?? 0, prompt.max ?? 0)) { store.chooseAmount($0) }
        case .multiAmount:
            MultiAmountPicker(message: prompt.message, rows: prompt.rows ?? []) { store.chooseAmounts($0) }
        case .pile:
            PilePicker(message: prompt.message, pile1: prompt.pile1 ?? [], pile2: prompt.pile2 ?? []) { store.choosePile($0) }
        case .target:
            TargetCardsPicker(message: prompt.message, cards: prompt.cards ?? []) { store.activate($0) }
        default:
            Text(prompt.message).padding()
        }
    }
}

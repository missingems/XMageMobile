import SwiftUI

struct CardDetailView: View {
    let card: Card
    var actionTitle: String?
    var action: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    CardArt(card: card, width: 280)
                        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(card.name)
                                .font(.title2.bold())
                            Spacer()
                            ManaCostView(cost: card.manaCost, size: 20)
                        }
                        if let typeLine = card.typeLine, !typeLine.isEmpty {
                            Text(typeLine)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(Array(card.rules.enumerated()), id: \.offset) { _, rule in
                            Text(rule)
                                .font(.body)
                        }
                        if card.showsPowerToughness, let power = card.power, let toughness = card.toughness {
                            LabeledContent("Power / Toughness", value: "\(power)/\(toughness)")
                        }
                        if let loyalty = card.loyalty {
                            LabeledContent("Loyalty", value: loyalty)
                        }
                        ForEach(card.counters, id: \.name) { counter in
                            LabeledContent("\(counter.name) counters", value: counter.count, format: .number)
                        }
                        if let set = card.set, !set.isEmpty {
                            Text("\(set.uppercased()) \(card.number ?? "")")
                                .font(.caption.monospaced())
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: 520, alignment: .leading)
                }
                .padding()
            }
            .navigationTitle(card.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
                if let actionTitle, let action {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(actionTitle, systemImage: "checkmark") {
                            dismiss()
                            action()
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

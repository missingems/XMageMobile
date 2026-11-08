import SwiftUI

struct DeckPickerView: View {
    let title: String
    let decks: [String]
    @Binding var selection: String

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        List {
            Section {
                row(label: "Random Deck", systemImage: "shuffle", value: "")
            }
            ForEach(sections, id: \.folder) { section in
                Section(section.folder) {
                    ForEach(section.decks) { deck in
                        row(label: deck.name, systemImage: nil, value: deck.path)
                    }
                }
            }
        }
        .navigationTitle(title)
        .searchable(text: $query, prompt: "Search decks")
    }

    private var sections: [(folder: String, decks: [DeckEntry])] {
        let filtered = query.isEmpty ? decks : decks.filter { $0.localizedStandardContains(query) }
        return DeckEntry.sections(filtered)
    }

    private func row(label: String, systemImage: String?, value: String) -> some View {
        Button {
            selection = value
            dismiss()
        } label: {
            HStack {
                if let systemImage {
                    Label(label, systemImage: systemImage)
                } else {
                    Text(label)
                }
                Spacer()
                if selection == value {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityLabel("Selected")
                }
            }
        }
        .foregroundStyle(.primary)
    }
}

import SwiftUI

struct ChoiceList: View {
    let message: String
    let choices: [PromptChoice]
    let onChoose: (PromptChoice) -> Void

    @State private var query = ""

    var body: some View {
        List {
            if !message.isEmpty {
                Section {
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                ForEach(filtered) { choice in
                    Button(choice.label) { onChoose(choice) }
                        .foregroundStyle(.primary)
                }
            }
        }
        .modifier(SearchableIfLong(isLong: choices.count > 8, query: $query))
    }

    private var filtered: [PromptChoice] {
        query.isEmpty ? choices : choices.filter { $0.label.localizedStandardContains(query) }
    }
}

private struct SearchableIfLong: ViewModifier {
    let isLong: Bool
    @Binding var query: String

    func body(content: Content) -> some View {
        if isLong {
            content.searchable(text: $query)
        } else {
            content
        }
    }
}

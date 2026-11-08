import SwiftUI

struct GameLogView: View {
    let lines: [LogLine]

    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    ForEach(lines) { line in
                        VStack(alignment: .leading, spacing: 2) {
                            if let turn = line.turnInfo, !turn.isEmpty {
                                Text(turn)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            Text(line.text)
                                .font(.footnote)
                                .foregroundStyle(line.isGameLog ? .primary : .secondary)
                        }
                        .id(line.id)
                    }
                } header: {
                    Text("Game Log")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
            .listStyle(.plain)
            .overlay {
                if lines.isEmpty {
                    ContentUnavailableView("No events yet", systemImage: "text.bubble")
                }
            }
            .onChange(of: lines.last?.id) { _, last in
                if let last {
                    withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                }
            }
        }
    }
}

import SwiftUI

struct OnlineTablesSection: View {
    let tables: [OnlineTable]
    let hasLoaded: Bool
    let isSeating: Bool
    let server: String
    let onCreate: () -> Void
    let onJoin: (OnlineTable) -> Void

    var body: some View {
        Section {
            Button(action: onCreate) {
                HStack {
                    Label("Create Table", systemImage: "plus.circle.fill")
                        .bold()
                    Spacer()
                    if isSeating {
                        ProgressView()
                    }
                }
            }
            if !hasLoaded {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Looking for open tables…")
                        .foregroundStyle(.secondary)
                }
            } else if tables.isEmpty {
                Text("No open tables right now. Create one and wait for an opponent.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(tables) { table in
                    OnlineTableRow(table: table) { onJoin(table) }
                }
            }
        } header: {
            Text("Play Online")
        } footer: {
            Text("Open two-player tables on \(server). Your deck must be legal in the table’s format.")
        }
        .disabled(isSeating)
    }
}

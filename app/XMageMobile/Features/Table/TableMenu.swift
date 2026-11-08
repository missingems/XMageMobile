import SwiftUI

struct TableMenu: View {
    @Environment(GameStore.self) private var store
    @Binding var showsLog: Bool
    @Binding var confirmsConcede: Bool

    var body: some View {
        Menu {
            Button("Game Log", systemImage: "text.bubble") { showsLog = true }
            Menu("Skip Ahead", systemImage: "forward.end.alt") {
                Button("To Next Turn", systemImage: "forward.end") { store.perform(.passUntilNextTurn) }
                Button("To End of Turn", systemImage: "moon") { store.perform(.passUntilEndOfTurn) }
                Button("To Next Main Phase", systemImage: "sparkles") { store.perform(.passUntilNextMain) }
                Button("Until Stack Resolves", systemImage: "square.stack") { store.perform(.passUntilStackResolved) }
                Button("To My Next Turn", systemImage: "person.crop.circle") { store.perform(.passUntilMyNextTurn) }
                Divider()
                Button("Stop Skipping", systemImage: "stop.circle") { store.perform(.cancelPasses) }
            }
            Divider()
            Button("Concede", systemImage: "flag.slash", role: .destructive) { confirmsConcede = true }
            Button("Leave Game", systemImage: "rectangle.portrait.and.arrow.right") { store.leaveGame() }
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.regular)
        .accessibilityLabel("Game Menu")
    }
}

import SwiftUI

struct NextGameWaitView: View {
    let onLeave: () -> Void

    @State private var confirmsLeave = false

    var body: some View {
        VStack(spacing: 18) {
            ProgressView()
                .controlSize(.large)
            Text("Deck Locked In")
                .font(.title2.bold())
            Text("The next game starts when your opponent finishes sideboarding.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Leave Match", role: .destructive) { confirmsLeave = true }
                .buttonStyle(.glass)
                .controlSize(.large)
        }
        .padding(28)
        .presentationDetents([.medium])
        .interactiveDismissDisabled()
        .confirmationDialog("Leave this match?", isPresented: $confirmsLeave, titleVisibility: .visible) {
            Button("Leave Match", role: .destructive, action: onLeave)
        } message: {
            Text("Your opponent wins the match.")
        }
    }
}

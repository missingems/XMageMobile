import SwiftUI

struct GameOverView: View {
    let result: GameResult
    let onRematch: (() -> Void)?
    let onLeave: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: result.won ? "trophy.fill" : "flag.fill")
                .font(.system(size: 56))
                .foregroundStyle(result.won ? AnyShapeStyle(.yellow.gradient) : AnyShapeStyle(.secondary))
                .symbolEffect(.bounce, value: result.id)
            Text(result.won ? "Victory" : "Defeat")
                .font(.largeTitle.bold())
            if !result.summary.isEmpty {
                Text(result.summary)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 10) {
                if let onRematch {
                    Button(action: onRematch) {
                        Text("Play Again").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    Button(action: onLeave) {
                        Text("Back to Lobby").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                } else {
                    Button(action: onLeave) {
                        Text("Back to Lobby").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .controlSize(.large)
            .frame(maxWidth: 320)
        }
        .padding(28)
        .presentationDetents([.medium])
        .interactiveDismissDisabled()
    }
}

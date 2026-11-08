import SwiftUI

struct RootView: View {
    @State private var store = GameStore()
    #if DEBUG
    @State private var autopilot: Autopilot? = {
        let turns = UserDefaults.standard.integer(forKey: "autopilotTurns")
        return turns > 0 ? Autopilot(turns: turns, holdStep: UserDefaults.standard.string(forKey: "autopilotHoldStep")) : nil
    }()
    #endif

    var body: some View {
        Group {
            if store.isInGame {
                GameScreen()
                    .transition(.opacity)
            } else {
                LobbyView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.isInGame)
        .environment(store)
        .task {
            await autoStartIfRequested()
        }
        #if DEBUG
        .onChange(of: store.prompt?.id) {
            guard let prompt = store.prompt, autopilot != nil else { return }
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                guard store.prompt?.id == prompt.id else { return }
                autopilot?.respond(to: prompt, in: store)
            }
        }
        #endif
    }

    private func autoStartIfRequested() async {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "autoStart") else { return }
        store.connect(ServerSettings(
            bridgeHost: defaults.string(forKey: "bridgeHost") ?? "localhost",
            bridgePort: defaults.object(forKey: "bridgePort") as? Int ?? 8765,
            serverHost: defaults.string(forKey: "serverHost") ?? "127.0.0.1",
            serverPort: defaults.object(forKey: "serverPort") as? Int ?? 17171,
            username: defaults.string(forKey: "username") ?? "Planeswalker"))
        while store.phase != .lobby {
            if case .failed = store.phase { return }
            try? await Task.sleep(for: .milliseconds(200))
        }
        store.startGame(deck: defaults.string(forKey: "deck").flatMap { $0.isEmpty ? nil : $0 },
                        opponentDeck: defaults.string(forKey: "opponentDeck").flatMap { $0.isEmpty ? nil : $0 })
    }
}

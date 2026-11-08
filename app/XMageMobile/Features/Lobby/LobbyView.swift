import SwiftUI

struct LobbyView: View {
    @Environment(GameStore.self) private var store

    @AppStorage("bridgeHost") private var bridgeHost = "localhost"
    @AppStorage("bridgePort") private var bridgePort = 8765
    @AppStorage("serverHost") private var serverHost = "127.0.0.1"
    @AppStorage("serverPort") private var serverPort = 17171
    @AppStorage("username") private var username = "Planeswalker"
    @AppStorage("deck") private var deck = ""
    @AppStorage("opponentDeck") private var opponentDeck = ""
    @State private var showsCreateTable = false
    @State private var passwordTable: OnlineTable?
    @State private var showsPasswordPrompt = false
    @State private var tablePassword = ""

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                header
                if store.phase.isConnected {
                    if let table = store.waitingTable {
                        WaitingRoomSection(table: table, isOwner: store.isTableOwner, onLeave: store.leaveTable)
                    } else {
                        deckSection
                        OnlineTablesSection(
                            tables: store.tables,
                            hasLoaded: store.hasLoadedTables,
                            isSeating: store.isSeating,
                            server: serverHost,
                            onCreate: { showsCreateTable = true },
                            onJoin: join)
                        if store.allowsComputer {
                            computerSection
                        }
                    }
                }
                connectionSection
            }
            .navigationTitle("XMage")
            .toolbar {
                if store.phase.isConnected {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Disconnect", systemImage: "bolt.horizontal.circle") { store.disconnect() }
                    }
                }
            }
            .animation(.default, value: store.phase)
            .animation(.default, value: store.waitingTable?.id)
            .sheet(isPresented: $showsCreateTable) {
                CreateTableView(formats: store.deckTypes, defaultName: "\(store.username ?? username)’s table") { format, name, password in
                    store.createTable(deck: chosenDeck, format: format, name: name, password: password)
                }
            }
            .alert("Table Password", isPresented: $showsPasswordPrompt, presenting: passwordTable) { table in
                SecureField("Password", text: $tablePassword)
                Button("Join") {
                    store.joinTable(table, deck: chosenDeck, password: tablePassword)
                }
                Button("Cancel", role: .cancel) {}
            } message: { table in
                Text("\(table.owner)’s table “\(table.title)” needs a password.")
            }
            .alert(store.lobbyAlert ?? "", isPresented: $store.showsLobbyAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private var chosenDeck: String? { deck.isEmpty ? nil : deck }

    private func join(_ table: OnlineTable) {
        if table.passworded {
            tablePassword = ""
            passwordTable = table
            showsPasswordPrompt = true
        } else {
            store.joinTable(table, deck: chosenDeck, password: nil)
        }
    }

    private var header: some View {
        Section {
            HStack(spacing: 14) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.accentColor.gradient)
                    .frame(width: 56, height: 56)
                    .background(.tint.opacity(0.12), in: .rect(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle).font(.headline)
                    Text(statusDetail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var statusTitle: String {
        switch store.phase {
        case .idle: "Not Connected"
        case .reachingBridge: "Reaching the Bridge…"
        case .loggingIn: "Signing In…"
        case .lobby: store.waitingTable == nil ? "Ready to Play" : "Waiting for an Opponent"
        case .startingGame: "Starting Game…"
        case .playing: "In a Game"
        case .failed: "Connection Problem"
        }
    }

    private var statusDetail: String {
        switch store.phase {
        case let .failed(message): message
        case .lobby, .startingGame, .playing:
            "Signed in as \(store.username ?? username) · XMage \(store.xmageVersion ?? "")"
        default: "Play rules-enforced Magic online or against the computer, powered by XMage."
        }
    }

    private var deckSection: some View {
        Section {
            NavigationLink {
                DeckPickerView(title: "Your Deck", decks: store.decks, selection: $deck)
            } label: {
                LabeledContent("Your Deck", value: label(for: deck))
            }
        } footer: {
            Text("\(store.decks.count) sample decks from XMage. A random deck is picked when none is chosen.")
        }
    }

    private var computerSection: some View {
        Section {
            NavigationLink {
                DeckPickerView(title: "Computer’s Deck", decks: store.decks, selection: $opponentDeck)
            } label: {
                LabeledContent("Computer’s Deck", value: label(for: opponentDeck))
            }
            Button {
                store.startGame(deck: chosenDeck, opponentDeck: opponentDeck.isEmpty ? nil : opponentDeck)
            } label: {
                HStack {
                    Spacer()
                    if store.phase == .startingGame {
                        ProgressView()
                    } else {
                        Label("Play vs Computer", systemImage: "play.fill").bold()
                    }
                    Spacer()
                }
            }
            .disabled(store.phase == .startingGame)
        } header: {
            Text("Practice")
        }
    }

    private var connectionSection: some View {
        Section {
            LabeledContent("Bridge") {
                TextField("Host", text: $bridgeHost)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
            }
            LabeledContent("Bridge Port") {
                TextField("Port", value: $bridgePort, format: .number.grouping(.never))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
            }
            LabeledContent("XMage Server") {
                TextField("Host", text: $serverHost)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
            }
            LabeledContent("Server Port") {
                TextField("Port", value: $serverPort, format: .number.grouping(.never))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
            }
            LabeledContent("Username") {
                TextField("Name", text: $username)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
            }
            Button(store.phase.isConnected ? "Reconnect" : "Connect") {
                store.connect(ServerSettings(bridgeHost: bridgeHost, bridgePort: bridgePort, serverHost: serverHost, serverPort: serverPort, username: username))
            }
            .disabled(store.phase.isBusy || bridgeHost.isEmpty || username.isEmpty)
        } header: {
            Text("Connection")
        } footer: {
            Text("The bridge runs next to the XMage server on your Mac or home server. The server address is as seen from the bridge.")
        }
    }

    private func label(for path: String) -> String {
        path.isEmpty ? "Random" : DeckEntry(path: path).name
    }
}

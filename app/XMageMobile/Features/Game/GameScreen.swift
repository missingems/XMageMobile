import SwiftUI

struct GameScreen: View {
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var motion

    @State private var metrics = TableMetrics(size: CGSize(width: 390, height: 700))
    @State private var inspected: Card?
    @State private var zone: ZoneRequest?
    @State private var showsLog = false
    @State private var confirmsConcede = false
    @State private var focusedHandId: String?
    @State private var seenReveals: Set<String> = []

    var body: some View {
        @Bindable var store = store
        ZStack {
            Playmat()
            if let state = store.game {
                Color.clear
                    .onGeometryChange(for: TableMetrics.self) { proxy in
                        TableMetrics(size: proxy.size, trailingInset: proxy.safeAreaInsets.trailing)
                    } action: { newValue in
                        metrics = newValue
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                    .overlay { table(state) }
                    .overlay(alignment: .bottomTrailing) { sideStrip(state) }
                    .overlay(alignment: .top) { toast }
                    .overlay { focusLayer(state) }
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .animation(reduceMotion ? nil : .snappy(duration: 0.35), value: motionKey(state))
            } else {
                ProgressView("Shuffling up…")
                    .tint(.white)
                    .foregroundStyle(.white)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onChange(of: store.game?.revealed?.map(\.signature) ?? []) { _, signatures in
            let groups = store.game?.revealed ?? []
            let fresh = groups.filter { !seenReveals.contains($0.signature) }
            seenReveals.formUnion(signatures)
            if let newest = fresh.last, store.presentedPrompt == nil, zone == nil, inspected == nil {
                showRevealed(newest)
            }
        }
        .onChange(of: store.game?.hand.map(\.id)) { _, ids in
            if let focusedHandId, ids?.contains(focusedHandId) != true {
                self.focusedHandId = nil
            }
        }
        .sheet(item: $inspected) { card in
            CardDetailView(card: card, actionTitle: actionTitle(for: card)) { store.activate(card) }
        }
        .sheet(item: $zone) { request in
            ZoneSheet(title: request.title, cards: request.cards) { store.activate($0) }
        }
        .sheet(item: $store.presentedPrompt) { prompt in
            PromptSheet(prompt: prompt)
        }
        .sheet(item: $store.matchSheet) { sheet in
            switch sheet {
            case let .result(result):
                GameOverView(result: result, onRematch: rematchAction, onLeave: store.leaveGame)
            case let .sideboard(session):
                SideboardView(session: session)
            case .waitingForNextGame:
                NextGameWaitView(onLeave: store.leaveGame)
            }
        }
        .sheet(isPresented: $showsLog) {
            GameLogView(lines: store.log)
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Concede this game?", isPresented: $confirmsConcede, titleVisibility: .visible) {
            Button("Concede", role: .destructive) { store.concede() }
        }
    }

    private var rematchAction: (() -> Void)? {
        if store.isOnlineMatch { return nil }
        return { store.rematch() }
    }

    private func table(_ state: GameState) -> some View {
        let opponent = state.opponents.first
        let order = combatOrder(state)
        return VStack(spacing: 0) {
            topBand(opponent, state: state)
                .frame(height: TableMetrics.topBand)
            VStack(spacing: 0) {
                if let opponent {
                    row(opponent.otherPermanents + opponent.lands, of: opponent, lands: true, state: state, direction: 1, order: order)
                    row(opponent.creatures, of: opponent, lands: false, state: state, direction: 1, order: order)
                }
            }
            .frame(maxHeight: .infinity)
            .overlay(alignment: .bottomTrailing) { stack(state) }
            centerBand(state)
                .frame(height: TableMetrics.centerGap)
            VStack(spacing: 0) {
                if let me = state.me {
                    row(me.creatures, of: me, lands: false, state: state, direction: -1, order: order)
                    row(me.otherPermanents + me.lands, of: me, lands: true, state: state, direction: -1, order: order)
                }
            }
            .frame(maxHeight: .infinity)
            bottomBand(state)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .overlayPreferenceValue(TableAnchorKey.self) { anchors in
            TableLines(state: state, anchors: anchors)
        }
    }

    private func topBand(_ opponent: Player?, state: GameState) -> some View {
        HStack(alignment: .top, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                if let opponent {
                    PlayerAvatar(player: opponent, identity: ManaIdentity.colors(of: opponent, in: state)) { store.choosePlayer(opponent) }
                    ZonePiles(player: opponent) { show($0, of: opponent) }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            OpponentHandFan(count: opponent?.handCount ?? 0)
            TableMenu(showsLog: $showsLog, confirmsConcede: $confirmsConcede,
                      revealed: state.revealed ?? [], onShowRevealed: showRevealed)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, TableMetrics.margin)
        .padding(.top, 8)
    }

    private func row(_ cards: [Card], of player: Player, lands: Bool, state: GameState, direction: Double, order: [String: Int]) -> some View {
        let sorted = lands ? cards : cards.enumerated()
            .sorted { (order[$0.element.id] ?? Int.max, $0.offset) < (order[$1.element.id] ?? Int.max, $1.offset) }
            .map(\.element)
        return PermanentRow(cards: sorted, player: player,
                            width: lands ? metrics.landCardWidth : metrics.creatureCardWidth,
                            groupsLands: lands, combat: (state.attackerIds, state.blockerIds),
                            attackDirection: direction, motion: motion,
                            onTap: tap, onInspect: inspect)
            .frame(height: lands ? metrics.landRowHeight : metrics.creatureRowHeight)
    }

    private func combatOrder(_ state: GameState) -> [String: Int] {
        var order: [String: Int] = [:]
        for (index, group) in state.combat.enumerated() {
            for id in group.attackerIds + group.blockerIds where order[id] == nil {
                order[id] = index
            }
        }
        return order
    }

    private func centerBand(_ state: GameState) -> some View {
        let message = centerMessage(state)
        return ZStack {
            if let message {
                Text(message)
                    .font(.footnote.weight(.medium))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: .capsule)
                    .id(message)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, TableMetrics.margin)
        .animation(.easeInOut(duration: 0.2), value: message)
    }

    private func centerMessage(_ state: GameState) -> String? {
        guard let prompt = store.prompt else { return store.waitingText }
        let step = state.step.flatMap(GameStep.init(rawValue:))
        if prompt.isPriority {
            if let top = state.stack.first {
                return "\(top.name) is on the stack · Respond or resolve"
            }
            guard let step else { return prompt.message }
            if state.isMyTurn {
                return step.isMain ? "Your \(step.phrase) · Play a card or pass" : "Your \(step.phrase) · Pass to continue"
            }
            return "Opponent’s \(step.phrase) · Play an instant or pass"
        }
        switch prompt.kind {
        case .select where step == .DECLARE_ATTACKERS && state.isMyTurn:
            return "Tap creatures to attack, then confirm"
        case .select where step == .DECLARE_BLOCKERS && !state.isMyTurn:
            return "Choose your blockers, then confirm"
        case .target:
            return "\(prompt.message) · Tap a glowing card or player"
        case .mana where prompt.specialLabel != nil:
            return "\(prompt.message) · Tap lands first, then \(prompt.specialLabel ?? "Special") for the rest"
        case .mana, .xmana:
            return "\(prompt.message) · Tap lands or your mana"
        default:
            return prompt.message.isEmpty ? nil : prompt.message
        }
    }

    private var toast: some View {
        ZStack {
            if let banner = store.banner {
                Text(banner)
                    .font(.footnote.weight(.medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassEffect(.regular, in: .capsule)
                    .padding(.top, TableMetrics.topBand + 4)
                    .padding(.horizontal, 48)
                    .id(banner)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: store.banner)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func stack(_ state: GameState) -> some View {
        ZStack {
            if !state.stack.isEmpty {
                StackColumn(cards: state.stack, width: metrics.stackCardWidth, motion: motion, onTap: tap, onInspect: inspect)
                    .fixedSize()
                    .padding(.trailing, TableMetrics.margin)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: state.stack.map(\.id))
    }

    private func bottomBand(_ state: GameState) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            HStack(alignment: .bottom, spacing: 10) {
                if let me = state.me {
                    PlayerAvatar(player: me, identity: ManaIdentity.colors(of: me, in: state)) { store.choosePlayer(me) }
                    ZonePiles(player: me) { show($0, of: me) }
                }
            }
            .padding(.leading, TableMetrics.margin)
            .padding(.bottom, TableMetrics.margin)
            .frame(width: metrics.sideColumn, alignment: .leading)
            .overlay(alignment: .topLeading) {
                if let me = state.me {
                    ManaPoolChips(pool: me.manaPool, canPay: isPayingMana, onPay: store.payMana)
                        .padding(.leading, TableMetrics.margin)
                        .offset(y: -44)
                }
            }
            HandFan(cards: state.hand, cardWidth: metrics.handCardWidth, availableWidth: metrics.handFanWidth,
                    focusedId: focusedHandId, motion: motion, onTap: tapHand)
                .padding(.top, 8)
                .frame(width: metrics.handFanWidth, height: metrics.bottomBand, alignment: .top)
            if !metrics.usesSideStrip {
                ActionCluster(state: state)
                    .padding(.trailing, TableMetrics.margin)
                    .padding(.bottom, TableMetrics.margin)
                    .frame(width: metrics.actionColumn, alignment: .trailing)
            }
        }
        .frame(height: metrics.bottomBand, alignment: .bottom)
    }

    @ViewBuilder
    private func sideStrip(_ state: GameState) -> some View {
        if metrics.usesSideStrip {
            ActionCluster(state: state, isStrip: true)
                .frame(width: metrics.sideStripWidth)
                .padding(.bottom, TableMetrics.margin)
                .offset(x: metrics.sideStripWidth + 6)
                .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    private func focusLayer(_ state: GameState) -> some View {
        ZStack(alignment: .bottom) {
            if let id = focusedHandId, let card = state.hand.first(where: { $0.id == id }) {
                Rectangle()
                    .fill(.black.opacity(0.5))
                    .ignoresSafeArea()
                    .contentShape(.rect)
                    .onTapGesture { focusedHandId = nil }
                    .accessibilityLabel("Close card")
                    .accessibilityAddTraits(.isButton)
                    .transition(.opacity)
                VStack(spacing: 14) {
                    Button {
                        canPlay(card) ? play(card) : showDetails(card)
                    } label: {
                        CardArt(card: card, width: metrics.focusedCardWidth)
                            .shadow(color: card.isActionable ? CardTile.playableEdge.opacity(0.5) : .black.opacity(0.5), radius: 16)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(card.name)
                    HStack(spacing: 10) {
                        Button("Details", systemImage: "info.circle") { showDetails(card) }
                            .buttonStyle(.glass)
                        Button(card.choosable ? "Choose" : "Play", systemImage: "play.fill") { play(card) }
                            .buttonStyle(.glassProminent)
                            .disabled(!canPlay(card))
                    }
                    .controlSize(.large)
                }
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: focusedHandId)
    }

    private func motionKey(_ state: GameState) -> [String] {
        state.hand.map(\.id) + state.stack.map(\.id) + state.players.flatMap { $0.battlefield.map(\.id) }
    }

    private var isPayingMana: Bool {
        store.prompt?.kind == .mana || store.prompt?.kind == .xmana
    }

    private func tapHand(_ card: Card) {
        if card.isLand, canPlay(card), store.prompt?.isPriority == true {
            store.activate(card)
        } else {
            focusedHandId = card.id
        }
    }

    private func canPlay(_ card: Card) -> Bool {
        card.isActionable && store.prompt != nil
    }

    private func play(_ card: Card) {
        focusedHandId = nil
        store.activate(card)
    }

    private func showDetails(_ card: Card) {
        focusedHandId = nil
        inspected = card
    }

    private func tap(_ card: Card) {
        if canPlay(card) {
            store.activate(card)
        } else {
            inspected = card
        }
    }

    private func inspect(_ card: Card) {
        inspected = card
    }

    private func actionTitle(for card: Card) -> String? {
        guard canPlay(card) else { return nil }
        return card.choosable ? "Choose" : "Play"
    }

    private func showRevealed(_ group: RevealedGroup) {
        focusedHandId = nil
        zone = ZoneRequest(title: group.heading, cards: group.cards)
    }

    private func show(_ zone: TableZone, of player: Player) {
        let cards: [Card] = switch zone {
        case .graveyard: player.graveyard.reversed()
        case .exile: player.exile
        case .command: player.command.map(\.asCard)
        case .companion: player.companion
        }
        self.zone = ZoneRequest(title: "\(player.name) · \(zone.rawValue)", cards: cards)
    }
}

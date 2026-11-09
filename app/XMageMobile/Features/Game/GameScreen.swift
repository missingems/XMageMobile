import SwiftUI

struct GameScreen: View {
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var motion

    @State private var metrics = TableMetrics(size: CGSize(width: 390, height: 700))
    @State private var inspected: Card?
    @State private var panelCard: Card?
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
                        TableMetrics(size: proxy.size, leadingInset: proxy.safeAreaInsets.leading, trailingInset: proxy.safeAreaInsets.trailing)
                    } action: { newValue in
                        metrics = newValue
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                    .overlay { table(state) }
                    .overlay(alignment: .bottomTrailing) { sideStrip(state) }
                    .overlay(alignment: .top) { toast }
                    .overlay { focusLayer(state) }
                    .overlay { detailPanel }
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
        Group {
            if metrics.isLandscape {
                landscapeTable(state)
            } else {
                portraitTable(state)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .overlayPreferenceValue(TableAnchorKey.self) { anchors in
            TableLines(state: state, anchors: anchors)
        }
    }

    private func portraitTable(_ state: GameState) -> some View {
        VStack(spacing: 0) {
            topBand(state.opponents.first, state: state)
                .frame(height: metrics.topBand)
            battlefield(state)
            bottomBand(state)
        }
    }

    private func landscapeTable(_ state: GameState) -> some View {
        VStack(spacing: 0) {
            landscapeTop(state)
                .frame(height: metrics.topBand)
            battlefield(state, showsStack: false)
                .rotation3DEffect(.degrees(TableMetrics.tableTilt), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.45)
                .padding(.horizontal, metrics.sideColumn)
                .padding(.bottom, 12)
                .overlay(alignment: .leading) { playerColumn(state) }
            landscapeBottom(state)
                .frame(height: metrics.bottomBand)
        }
        .overlay(alignment: .topTrailing) {
            stack(state)
                .padding(.top, metrics.topBand + 4)
                .padding(.trailing, metrics.trailingInset)
        }
        .overlay(alignment: .bottomTrailing) {
            ActionCluster(state: state, showsPhase: false)
                .frame(width: metrics.actionColumn)
                .padding(.trailing, metrics.trailingInset + TableMetrics.margin)
                .padding(.bottom, metrics.bottomBand + 4)
        }
        .frame(width: metrics.fullWidth)
        .offset(x: (metrics.trailingInset - metrics.leadingInset) / 2)
    }

    private func battlefield(_ state: GameState, showsStack: Bool = true) -> some View {
        let order = combatOrder(state)
        return VStack(spacing: 0) {
            VStack(spacing: 0) {
                if let opponent = state.opponents.first {
                    row(opponent.otherPermanents + opponent.lands, of: opponent, lands: true, state: state, direction: 1, order: order)
                    row(opponent.creatures, of: opponent, lands: false, state: state, direction: 1, order: order)
                }
            }
            .frame(maxHeight: .infinity)
            .overlay(alignment: .bottomTrailing) {
                if showsStack { stack(state) }
            }
            centerBand(state)
                .frame(height: metrics.centerGap)
            VStack(spacing: 0) {
                if let me = state.me {
                    row(me.creatures, of: me, lands: false, state: state, direction: -1, order: order)
                    row(me.otherPermanents + me.lands, of: me, lands: true, state: state, direction: -1, order: order)
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func landscapeTop(_ state: GameState) -> some View {
        let opponent = state.opponents.first
        return ZStack(alignment: .top) {
            OpponentHandFan(count: opponent?.handCount ?? 0)
                .offset(y: -OpponentHandFan.cardHeight * 0.55)
            HStack(alignment: .top, spacing: 12) {
                if let opponent {
                    ZonePiles(player: opponent) { show($0, of: opponent) }
                }
                Spacer(minLength: 0)
                TableMenu(showsLog: $showsLog, confirmsConcede: $confirmsConcede,
                          revealed: state.revealed ?? [], onShowRevealed: showRevealed)
            }
            .padding(.leading, metrics.leadingInset + TableMetrics.margin)
            .padding(.trailing, metrics.trailingInset + TableMetrics.margin)
            .padding(.top, 4)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func playerColumn(_ state: GameState) -> some View {
        VStack(spacing: metrics.centerGap + 4) {
            if let opponent = state.opponents.first {
                LifePlate(player: opponent, state: state, identity: ManaIdentity.colors(of: opponent, in: state)) { store.choosePlayer(opponent) }
            }
            if let me = state.me {
                LifePlate(player: me, state: state, identity: ManaIdentity.colors(of: me, in: state)) { store.choosePlayer(me) }
                    .overlay(alignment: .bottom) {
                        ManaPoolChips(pool: me.manaPool, canPay: isPayingMana, onPay: store.payMana)
                            .fixedSize()
                            .alignmentGuide(.bottom) { $0[.top] - 8 }
                    }
            }
        }
        .frame(width: max(120, metrics.sideColumn))
        .padding(.bottom, 12)
    }

    private func landscapeBottom(_ state: GameState) -> some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: metrics.lifeRow)
                HandFan(cards: state.hand, cardWidth: metrics.handCardWidth, availableWidth: metrics.handFanWidth,
                        focusedId: focusedHandId, motion: motion, onTap: tapHand)
                    .frame(width: metrics.handFanWidth, height: metrics.handBand, alignment: .top)
            }
            .frame(maxWidth: .infinity)
            if let me = state.me {
                ZonePiles(player: me, isMirrored: true) { show($0, of: me) }
                    .padding(.trailing, metrics.trailingInset + TableMetrics.margin)
                    .padding(.bottom, 10)
            }
        }
    }

    private func topBand(_ opponent: Player?, state: GameState) -> some View {
        ZStack(alignment: .top) {
            OpponentHandFan(count: opponent?.handCount ?? 0)
                .offset(y: -OpponentHandFan.cardHeight * 0.5)
            HStack(alignment: .top, spacing: 8) {
                if let opponent {
                    ZonePiles(player: opponent) { show($0, of: opponent) }
                }
                Spacer(minLength: 0)
                TableMenu(showsLog: $showsLog, confirmsConcede: $confirmsConcede,
                          revealed: state.revealed ?? [], onShowRevealed: showRevealed)
            }
            .padding(.horizontal, TableMetrics.margin)
            if let opponent {
                PlayerAvatar(player: opponent, identity: ManaIdentity.colors(of: opponent, in: state)) { store.choosePlayer(opponent) }
                    .padding(.top, 10)
            }
        }
        .padding(.top, 6)
        .frame(maxHeight: .infinity, alignment: .top)
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
            LinearGradient(colors: [.clear, .white.opacity(0.16), .clear], startPoint: .leading, endPoint: .trailing)
                .frame(height: 1)
            if metrics.isLandscape {
                PhaseRail(side: .all, current: state.step.flatMap(GameStep.init(rawValue:)), isActive: true, length: 150,
                          litColor: state.isMyTurn ? PhaseRail.lit : Color(red: 1, green: 0.42, blue: 0.36))
                    .accessibilityElement()
                    .accessibilityLabel("\(state.isMyTurn ? "Your" : "Opponent’s") turn, \(state.step.flatMap(GameStep.init(rawValue:))?.title ?? "")")
            }
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
        if prompt.isPriority, metrics.isLandscape {
            return nil
        }
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
                    .padding(.top, metrics.topBand + 4)
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
        VStack(spacing: 0) {
            playerHUD(state)
                .frame(height: metrics.lifeRow)
            HandFan(cards: state.hand, cardWidth: metrics.handCardWidth, availableWidth: metrics.handFanWidth,
                    focusedId: focusedHandId, motion: motion, onTap: tapHand)
                .frame(width: metrics.handFanWidth, height: metrics.handBand, alignment: .top)
                .frame(maxWidth: .infinity, alignment: metrics.usesSideStrip ? .center : .leading)
        }
        .overlay(alignment: .bottomTrailing) {
            if !metrics.usesSideStrip {
                ActionCluster(state: state)
                    .padding(.trailing, TableMetrics.margin)
                    .padding(.bottom, TableMetrics.margin)
                    .frame(width: metrics.actionColumn, alignment: .trailing)
            }
        }
        .frame(height: metrics.bottomBand, alignment: .top)
    }

    private func playerHUD(_ state: GameState) -> some View {
        ZStack {
            HStack(spacing: 8) {
                if let me = state.me {
                    ZonePiles(player: me) { show($0, of: me) }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, TableMetrics.margin)
            if let me = state.me {
                PlayerAvatar(player: me, identity: ManaIdentity.colors(of: me, in: state)) { store.choosePlayer(me) }
                    .overlay(alignment: .trailing) {
                        ManaPoolChips(pool: me.manaPool, canPay: isPayingMana, onPay: store.payMana)
                            .fixedSize()
                            .alignmentGuide(.trailing) { $0[.leading] - 10 }
                    }
            }
        }
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
            inspect(card)
        }
    }

    private func inspect(_ card: Card) {
        if metrics.isLandscape {
            panelCard = card
        } else {
            inspected = card
        }
    }

    private var detailPanel: some View {
        let width = min(250, metrics.size.height * 0.56 * CardFrameStyle.aspectRatio)
        return ZStack(alignment: .trailing) {
            if let card = panelCard {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .contentShape(.rect)
                    .onTapGesture { panelCard = nil }
                    .accessibilityLabel("Close card")
                    .accessibilityAddTraits(.isButton)
                    .transition(.opacity)
                VStack(spacing: 12) {
                    CardArt(card: card, width: width)
                        .shadow(color: .black.opacity(0.6), radius: 16, y: 6)
                        .accessibilityLabel(card.name)
                    HStack(spacing: 10) {
                        Button("Details", systemImage: "info.circle") {
                            panelCard = nil
                            inspected = card
                        }
                        .buttonStyle(.glass)
                        if canPlay(card) {
                            Button(card.choosable ? "Choose" : "Play", systemImage: "play.fill") {
                                panelCard = nil
                                store.activate(card)
                            }
                            .buttonStyle(.glassProminent)
                        }
                    }
                }
                .padding(.trailing, TableMetrics.margin + 8)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .animation(.snappy, value: panelCard?.id)
        #if DEBUG
        .task {
            if let id = UserDefaults.standard.string(forKey: "sampleInspect"), let card = store.game?.card(withId: id) {
                panelCard = card
            }
        }
        #endif
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

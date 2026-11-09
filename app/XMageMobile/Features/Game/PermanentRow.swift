import SwiftUI

struct PermanentRow: View {
    let cards: [Card]
    let player: Player
    let width: Double
    let groupsLands: Bool
    let combat: (attackers: Set<String>, blockers: Set<String>)
    var attackDirection = -1.0
    var motion: Namespace.ID?
    let onTap: (Card) -> Void
    let onInspect: (Card) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .center, spacing: width * 0.12) {
                if groupsLands {
                    ForEach(LandGroup.group(cards)) { group in
                        tile(group.representative, count: group.cards.count)
                    }
                } else {
                    ForEach(cards) { card in
                        tile(card, count: 1)
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: width / CardCrop.aspectRatio)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .defaultScrollAnchor(.center, for: .alignment)
        .defaultScrollAnchor(.leading, for: .initialOffset)
        .defaultScrollAnchor(.leading, for: .sizeChanges)
    }

    private func tile(_ card: Card, count: Int) -> some View {
        PermanentStack(card: card, attachments: player.attachments(of: card), width: width, count: count, combatRole: role(for: card), attackDirection: attackDirection, motion: motion, onTap: onTap, onInspect: onInspect)
    }

    private func role(for card: Card) -> CombatRole? {
        if combat.attackers.contains(card.id) { return .attacking }
        if combat.blockers.contains(card.id) { return .blocking }
        return nil
    }
}

import SwiftUI

struct PermanentStack: View {
    let card: Card
    let attachments: [Card]
    let width: Double
    let count: Int
    let combatRole: CombatRole?
    var attackDirection = -1.0
    var motion: Namespace.ID?
    let onTap: (Card) -> Void
    let onInspect: (Card) -> Void

    var body: some View {
        let peek = width * 0.24
        ZStack(alignment: .leading) {
            ForEach(Array(attachments.enumerated().reversed()), id: \.element.id) { index, attachment in
                CardTile(card: attachment, width: width, style: .battlefield)
                    .offset(x: Double(index + 1) * peek)
                    .tableAnchor(attachment.id)
                    .onTapGesture { onTap(attachment) }
            }
            CardTile(card: card, width: width, style: .battlefield, combatRole: combatRole, count: count)
                .cardMotion(card.id, in: motion)
                .tableAnchor(card.id)
                .onTapGesture { onTap(card) }
                .contextMenu {
                    if card.isActionable {
                        Button(card.choosable ? "Choose" : "Play", systemImage: "hand.tap") { onTap(card) }
                    }
                    Button("Details", systemImage: "info.circle") { onInspect(card) }
                } preview: {
                    CardArt(card: card, width: 260)
                }
        }
        .padding(.trailing, Double(attachments.count) * peek)
        .offset(y: combatRole == .attacking ? attackDirection * width * 0.22 : 0)
        .animation(.snappy, value: combatRole)
    }
}

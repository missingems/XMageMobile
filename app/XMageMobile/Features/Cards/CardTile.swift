import SwiftUI

struct CardTile: View {
    let card: Card
    let width: Double
    var combatRole: CombatRole?
    var count = 1
    var showsTapped = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var height: Double { width / CardFrameStyle.aspectRatio }
    private var isTapped: Bool { showsTapped && card.isTapped }
    private var scale: Double { width / 80 }

    var body: some View {
        ZStack {
            if count > 1 {
                stackShadow
            }
            CardArt(card: card, width: width)
                .saturation(isResting ? 0.45 : 1)
                .brightness(isResting ? -0.06 : 0)
                .overlay { highlight }
                .shadow(color: glowColor.opacity(card.choosable ? 0.7 : card.playable ? 0.45 : 0), radius: (card.choosable ? 6 : 4) * scale)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                .rotationEffect(.degrees(isTapped ? 90 : 0))
            CardBadges(card: card, combatRole: combatRole, count: count, scale: scale)
                .frame(width: isTapped ? height : width, height: isTapped ? width : height)
            if card.selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18 * scale))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .tint)
            }
        }
        .frame(width: isTapped ? height : width, height: height)
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: isTapped)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(card.isActionable ? .isButton : [])
    }

    private var stackShadow: some View {
        RoundedRectangle(cornerRadius: CardFrameStyle.cornerRadius(forWidth: width))
            .fill(.black.opacity(0.35))
            .frame(width: width, height: height)
            .offset(x: 3 * scale, y: -3 * scale)
            .rotationEffect(.degrees(isTapped ? 90 : 0))
    }

    private var isResting: Bool {
        card.summoningSick == true && card.isCreature && !card.isTapped
    }

    static let playableEdge = Color(red: 0.62, green: 0.82, blue: 1)

    private var glowColor: Color {
        card.choosable ? .yellow : Self.playableEdge
    }

    @ViewBuilder
    private var highlight: some View {
        let shape = RoundedRectangle(cornerRadius: CardFrameStyle.cornerRadius(forWidth: width))
        if card.choosable {
            shape.strokeBorder(.yellow, lineWidth: max(2, 2.5 * scale))
                .phaseAnimator([0.45, 1.0]) { content, phase in
                    content.opacity(reduceMotion ? 1 : phase)
                } animation: { _ in .easeInOut(duration: 0.8) }
        } else if card.playable {
            shape.strokeBorder(Self.playableEdge, lineWidth: max(1, 1.5 * scale))
        } else if let combatRole {
            shape.strokeBorder(combatRole.tint, lineWidth: max(1.5, 2 * scale))
        }
    }

    private var accessibilityText: Text {
        var parts = [card.name]
        if card.showsPowerToughness, let power = card.power, let toughness = card.toughness { parts.append("\(power)/\(toughness)") }
        if isTapped { parts.append("tapped") }
        if isResting { parts.append("summoning sick") }
        if count > 1 { parts.append("\(count) copies") }
        if combatRole == .attacking { parts.append("attacking") }
        if combatRole == .blocking { parts.append("blocking") }
        if card.playable { parts.append("playable") }
        if card.choosable { parts.append("can be chosen") }
        return Text(parts.joined(separator: ", "))
    }
}

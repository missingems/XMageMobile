import SwiftUI

struct CardTile: View {
    enum Style { case full, battlefield }

    let card: Card
    let width: Double
    var style = Style.full
    var combatRole: CombatRole?
    var count = 1
    var showsTapped = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var height: Double {
        width / (style == .battlefield ? CardCrop.aspectRatio : CardFrameStyle.aspectRatio)
    }

    private var cornerRadius: Double {
        style == .battlefield ? CardCrop.cornerRadius(forWidth: width) : CardFrameStyle.cornerRadius(forWidth: width)
    }
    private var isTapped: Bool { showsTapped && card.isTapped }
    private var scale: Double { width / 80 }

    var body: some View {
        ZStack {
            if isFlying {
                Ellipse()
                    .fill(.black.opacity(0.35))
                    .frame(width: width * 0.8, height: width * 0.16)
                    .blur(radius: 4 * scale)
                    .offset(y: height * 0.5)
            }
            face
                .rotationEffect(.degrees(isTapped ? 14 : 0), anchor: .center)
                .modifier(Hover(isOn: isFlying && !reduceMotion, lift: 5 * scale))
        }
        .frame(width: width, height: height)
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: isTapped)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(card.isActionable ? .isButton : [])
    }

    private var isFlying: Bool {
        style == .battlefield && !isTapped && Keyword.parse(card.rules).contains(.flying)
    }

    private var face: some View {
        ZStack {
            if count > 1 {
                stackShadow
            }
            art
                .saturation(isTapped ? 0.55 : isResting ? 0.45 : 1)
                .brightness(isTapped ? -0.22 : isResting ? -0.06 : 0)
                .overlay { highlight }
                .shadow(color: glowColor.opacity(card.choosable ? 0.7 : card.playable ? 0.45 : 0), radius: (card.choosable ? 6 : 4) * scale)
                .shadow(color: .black.opacity(isFlying ? 0 : 0.35), radius: 2, y: 1)
            CardBadges(card: card, combatRole: combatRole, count: count, scale: scale, isProminent: style == .battlefield)
                .frame(width: width, height: height)
            if isTapped {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 15 * scale, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 30 * scale, height: 30 * scale)
                    .background(.black.opacity(0.6), in: .circle)
                    .overlay { Circle().stroke(.white.opacity(0.5), lineWidth: 1) }
                    .accessibilityHidden(true)
            }
            if card.selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18 * scale))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .tint)
            }
        }
    }

    @ViewBuilder
    private var art: some View {
        switch style {
        case .full: CardArt(card: card, width: width)
        case .battlefield: CardCrop(card: card, width: width)
        }
    }

    private var stackShadow: some View {
        let ghosts = min(count - 1, 3)
        return ZStack {
            ForEach((1...max(ghosts, 1)).reversed(), id: \.self) { index in
                Group {
                    if style == .battlefield {
                        art.brightness(-0.18 - 0.06 * Double(index))
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius).fill(.black.opacity(0.35))
                    }
                }
                .frame(width: width, height: height)
                .shadow(color: .black.opacity(0.4), radius: 1.5, y: 1)
                .offset(x: Double(index) * 5 * scale, y: Double(index) * -4 * scale)
            }
        }
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
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
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

private struct Hover: ViewModifier {
    let isOn: Bool
    let lift: Double

    func body(content: Content) -> some View {
        if isOn {
            content
                .phaseAnimator([0.0, 1.0]) { view, phase in
                    view.offset(y: -lift - lift * 0.6 * phase)
                } animation: { _ in .easeInOut(duration: 1.6) }
        } else {
            content
        }
    }
}

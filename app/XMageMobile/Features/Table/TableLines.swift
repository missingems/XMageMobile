import SwiftUI

struct TableLines: View {
    let state: GameState
    let anchors: [String: Anchor<CGRect>]

    private enum Kind { case block, attack, target }

    private struct Segment {
        let from: CGPoint
        let to: CGPoint
        let kind: Kind
    }

    var body: some View {
        GeometryReader { proxy in
            let segments = segments(in: proxy)
            Canvas { context, _ in
                for segment in segments {
                    draw(segment, in: &context)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func segments(in proxy: GeometryProxy) -> [Segment] {
        func center(_ id: String?) -> CGPoint? {
            guard let id, let anchor = anchors[id] else { return nil }
            let rect = proxy[anchor]
            return CGPoint(x: rect.midX, y: rect.midY)
        }
        var result: [Segment] = []
        for group in state.combat {
            for attacker in group.attackerIds {
                guard let attackerPoint = center(attacker) else { continue }
                if group.blockerIds.isEmpty {
                    if let defender = center(group.defenderId) {
                        result.append(Segment(from: attackerPoint, to: defender, kind: .attack))
                    }
                } else {
                    for blocker in group.blockerIds {
                        if let blockerPoint = center(blocker) {
                            result.append(Segment(from: blockerPoint, to: attackerPoint, kind: .block))
                        }
                    }
                }
            }
        }
        for card in state.stack {
            guard let source = center(card.id) else { continue }
            for target in card.targetIds ?? [] {
                if let point = center(target) {
                    result.append(Segment(from: source, to: point, kind: .target))
                }
            }
        }
        return result
    }

    private func draw(_ segment: Segment, in context: inout GraphicsContext) {
        let from = segment.from
        let to = segment.to
        let dx = to.x - from.x
        let dy = to.y - from.y
        let length = max(1, hypot(dx, dy))
        let bend = min(90, length * 0.28)
        let control = CGPoint(x: (from.x + to.x) / 2 - dy / length * bend * 0.35,
                              y: min(from.y, to.y) - bend)
        let tx = to.x - control.x
        let ty = to.y - control.y
        let tl = max(1, hypot(tx, ty))
        let ux = tx / tl
        let uy = ty / tl
        let headLength = 18.0
        let end = CGPoint(x: to.x - ux * (headLength + 6), y: to.y - uy * (headLength + 6))

        let core: Color
        let glow: Color
        switch segment.kind {
        case .block:
            core = Color(red: 0.55, green: 0.78, blue: 1)
            glow = Color(red: 0.2, green: 0.5, blue: 1)
        case .attack:
            core = Color(red: 1, green: 0.72, blue: 0.45)
            glow = Color(red: 1, green: 0.32, blue: 0.12)
        case .target:
            core = Color(red: 1, green: 0.93, blue: 0.75)
            glow = Color(red: 1, green: 0.55, blue: 0.15)
        }

        var line = Path()
        line.move(to: from)
        line.addQuadCurve(to: end, control: control)

        var glowContext = context
        glowContext.addFilter(.blur(radius: 6))
        glowContext.stroke(line, with: .color(glow.opacity(0.85)), style: StrokeStyle(lineWidth: 12, lineCap: .round))
        context.stroke(line, with: .linearGradient(Gradient(colors: [glow.opacity(0.3), core]), startPoint: from, endPoint: end),
                       style: StrokeStyle(lineWidth: 6, lineCap: .round))

        let tip = CGPoint(x: to.x - ux * 4, y: to.y - uy * 4)
        let base = CGPoint(x: tip.x - ux * headLength, y: tip.y - uy * headLength)
        var head = Path()
        head.move(to: tip)
        head.addLine(to: CGPoint(x: base.x + uy * 12, y: base.y - ux * 12))
        head.addLine(to: CGPoint(x: base.x - ux * 3, y: base.y - uy * 3))
        head.addLine(to: CGPoint(x: base.x - uy * 12, y: base.y + ux * 12))
        head.closeSubpath()
        glowContext.fill(head, with: .color(glow))
        context.fill(head, with: .color(core))
        context.stroke(head, with: .color(glow), lineWidth: 1.5)
    }
}

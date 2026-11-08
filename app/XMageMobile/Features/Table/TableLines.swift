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
        let dx = segment.to.x - segment.from.x
        let dy = segment.to.y - segment.from.y
        let length = max(1, hypot(dx, dy))
        let ux = dx / length
        let uy = dy / length
        let end = CGPoint(x: segment.to.x - ux * 16, y: segment.to.y - uy * 16)

        let color: Color
        let style: StrokeStyle
        switch segment.kind {
        case .block:
            color = Color(red: 1, green: 0.45, blue: 0.32)
            style = StrokeStyle(lineWidth: 3, lineCap: .round)
        case .attack:
            color = Color(red: 1, green: 0.45, blue: 0.32).opacity(0.7)
            style = StrokeStyle(lineWidth: 2, lineCap: .round, dash: [6, 6])
        case .target:
            color = Color(red: 0.62, green: 0.82, blue: 1)
            style = StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [8, 5])
        }

        var line = Path()
        line.move(to: segment.from)
        line.addLine(to: end)
        context.stroke(line, with: .color(.black.opacity(0.45)), style: StrokeStyle(lineWidth: style.lineWidth + 2.5, lineCap: .round, dash: style.dash))
        context.stroke(line, with: .color(color), style: style)

        let size = 10.0
        var head = Path()
        head.move(to: CGPoint(x: end.x + ux * 6, y: end.y + uy * 6))
        head.addLine(to: CGPoint(x: end.x - ux * size + uy * size * 0.6, y: end.y - uy * size - ux * size * 0.6))
        head.addLine(to: CGPoint(x: end.x - ux * size - uy * size * 0.6, y: end.y - uy * size + ux * size * 0.6))
        head.closeSubpath()
        context.fill(head, with: .color(color))
    }
}

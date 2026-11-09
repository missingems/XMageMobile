import SwiftUI

struct Playmat: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(colors: [Color(red: 0.36, green: 0.28, blue: 0.20), Color(red: 0.30, green: 0.23, blue: 0.16)],
                               startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [Color(red: 0.78, green: 0.64, blue: 0.46).opacity(0.75), .clear],
                               center: .center, startRadius: 0, endRadius: max(size.width, size.height) * 0.55)
                Canvas { context, canvasSize in
                    var generator = SeededGenerator(seed: 7)
                    let count = Int(canvasSize.width * canvasSize.height / 90)
                    for _ in 0..<count {
                        let x = Double.random(in: 0..<canvasSize.width, using: &generator)
                        let y = Double.random(in: 0..<canvasSize.height, using: &generator)
                        let light = Bool.random(using: &generator)
                        let rect = CGRect(x: x, y: y, width: 1.2, height: 1.2)
                        context.fill(Path(ellipseIn: rect), with: .color(light ? .white.opacity(0.05) : .black.opacity(0.07)))
                    }
                }
                RoundedRectangle(cornerRadius: 28)
                    .fill(.black.opacity(0.06))
                    .strokeBorder(.black.opacity(0.28), lineWidth: 2)
                    .padding(.horizontal, size.width * 0.08)
                    .padding(.top, size.height * 0.1)
                    .padding(.bottom, size.height * 0.16)
                    .rotation3DEffect(.degrees(TableMetrics.tableTilt), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.45)
                RadialGradient(colors: [.clear, .black.opacity(0.6)], center: .center,
                               startRadius: min(size.width, size.height) * 0.4, endRadius: max(size.width, size.height) * 0.72)
            }
            .drawingGroup()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

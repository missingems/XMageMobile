import SwiftUI

struct Playmat: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.11), Color(white: 0.07)], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [.white.opacity(0.06), .clear], center: .center, startRadius: 0, endRadius: 600)
            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(height: 0.5)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

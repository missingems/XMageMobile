import SwiftUI

struct ManaCostView: View {
    let cost: String?
    var size = 14.0

    var body: some View {
        let symbols = ManaSymbol.symbols(in: cost)
        if !symbols.isEmpty {
            HStack(spacing: 1.5) {
                ForEach(Array(symbols.enumerated()), id: \.offset) { _, symbol in
                    ManaSymbol(symbol: symbol, size: size)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(Text("Cost \(cost ?? "")"))
        }
    }
}

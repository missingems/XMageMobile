import SwiftUI

struct ManaPoolChips: View {
    let pool: ManaPool
    let canPay: Bool
    let onPay: (String) -> Void

    var body: some View {
        if !pool.isEmpty {
            HStack(spacing: 8) {
                ForEach(pool.entries, id: \.symbol) { entry in
                    Button {
                        onPay(entry.symbol)
                    } label: {
                        HStack(spacing: 2) {
                            ManaSymbol(symbol: entry.symbol, size: 18)
                            Text(entry.count, format: .number)
                                .font(.footnote.weight(.semibold).monospacedDigit())
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!canPay)
                    .accessibilityLabel("\(entry.count) \(entry.symbol) mana")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect(.regular, in: .capsule)
        }
    }
}

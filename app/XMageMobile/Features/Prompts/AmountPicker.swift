import SwiftUI

struct AmountPicker: View {
    let message: String
    let range: ClosedRange<Int>
    let onChoose: (Int) -> Void

    @State private var value: Int

    init(message: String, range: ClosedRange<Int>, onChoose: @escaping (Int) -> Void) {
        self.message = message
        self.range = range
        self.onChoose = onChoose
        _value = State(initialValue: range.lowerBound)
    }

    var body: some View {
        Form {
            Section {
                Text(message)
                    .foregroundStyle(.secondary)
            }
            Section {
                Stepper(value: $value, in: range) {
                    Text(value, format: .number)
                        .font(.system(.largeTitle, design: .rounded).bold())
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(value)))
                }
            } footer: {
                Text("Between \(range.lowerBound) and \(range.upperBound)")
            }
            Section {
                Button("Choose \(value)") { onChoose(value) }
                    .frame(maxWidth: .infinity)
                    .bold()
            }
        }
    }
}

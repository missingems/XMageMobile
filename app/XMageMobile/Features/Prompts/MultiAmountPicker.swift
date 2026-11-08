import SwiftUI

struct MultiAmountPicker: View {
    let message: String
    let rows: [AmountRow]
    let onChoose: ([Int]) -> Void

    @State private var values: [Int]

    init(message: String, rows: [AmountRow], onChoose: @escaping ([Int]) -> Void) {
        self.message = message
        self.rows = rows
        self.onChoose = onChoose
        _values = State(initialValue: rows.map(\.value))
    }

    var body: some View {
        Form {
            Section {
                Text(message).foregroundStyle(.secondary)
            }
            Section {
                ForEach(rows.indices, id: \.self) { index in
                    Stepper(value: $values[index], in: rows[index].min...max(rows[index].min, rows[index].max)) {
                        LabeledContent(rows[index].label, value: values[index], format: .number)
                    }
                }
            }
            Section {
                Button("Done") { onChoose(values) }
                    .frame(maxWidth: .infinity)
                    .bold()
            }
        }
    }
}

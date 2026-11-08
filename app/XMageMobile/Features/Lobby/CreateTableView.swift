import SwiftUI

struct CreateTableView: View {
    let formats: [String]
    let defaultName: String
    let onCreate: (_ format: String?, _ name: String?, _ password: String?, _ bestOf: Int, _ rated: Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("tableFormat") private var format = CreateTableView.modern
    @AppStorage("tableBestOf") private var bestOf = 1
    @AppStorage("tableRated") private var rated = false
    @State private var name = ""
    @State private var password = ""

    private static let freeform = "Constructed - Freeform Unlimited"
    private static let modern = "Constructed - Modern"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Table Name", text: $name, prompt: Text(defaultName))
                    if !formats.isEmpty {
                        Picker("Format", selection: $format) {
                            ForEach(formats, id: \.self) { type in
                                Text(OnlineTable.formatName(type)).tag(type)
                            }
                        }
                    }
                } footer: {
                    Text("Your deck must be legal in this format. Freeform Unlimited accepts any deck.")
                }
                Section {
                    Picker("Match", selection: $bestOf) {
                        Text("Single Game").tag(1)
                        Text("Best of Three").tag(3)
                    }
                } footer: {
                    Text("In best of three, you can swap cards with your sideboard between games.")
                }
                Section {
                    Toggle("Ranked", isOn: $rated)
                } footer: {
                    Text("Ranked matches change both players’ ratings on this server. Leaving early counts as a loss.")
                }
                Section {
                    SecureField("Password (Optional)", text: $password)
                } footer: {
                    Text("With a password, only friends you share it with can join.")
                }
            }
            .navigationTitle("New Table")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", role: .confirm) {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        onCreate(formats.isEmpty ? nil : format, trimmed.isEmpty ? nil : trimmed, password.isEmpty ? nil : password, bestOf, rated)
                        dismiss()
                    }
                }
            }
            .onAppear {
                if !formats.isEmpty && !formats.contains(format) {
                    format = formats.contains(Self.freeform) ? Self.freeform : formats[0]
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

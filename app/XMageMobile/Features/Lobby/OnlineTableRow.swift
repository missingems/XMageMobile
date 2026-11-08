import SwiftUI

struct OnlineTableRow: View {
    let table: OnlineTable
    let onJoin: () -> Void

    var body: some View {
        Button(action: onJoin) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(table.title)
                            .font(.body.weight(.semibold))
                            .lineLimit(1)
                        if table.passworded {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("Password protected")
                        }
                        if table.rated {
                            Text("Rated")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.fill.tertiary, in: .capsule)
                        }
                    }
                    Text("\(table.owner) · \(table.format)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if !table.info.isEmpty {
                        Text(table.info)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                Text("Join")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
            }
            .contentShape(.rect)
        }
        .foregroundStyle(.primary)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Joins \(table.owner)’s table")
    }
}

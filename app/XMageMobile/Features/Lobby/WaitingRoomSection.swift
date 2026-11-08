import SwiftUI

struct WaitingRoomSection: View {
    let table: OnlineTable
    let isOwner: Bool
    let onLeave: () -> Void

    var body: some View {
        Section {
            LabeledContent("Table", value: table.title)
            LabeledContent("Format", value: table.format)
            if table.rated {
                LabeledContent("Match", value: "Ranked")
            }
            ForEach(Array(table.seats.enumerated()), id: \.offset) { _, seat in
                Label {
                    LabeledContent {
                        if let rating = seat.rating, !seat.isOpen {
                            Text(rating, format: .number.grouping(.never))
                        }
                    } label: {
                        Text(seat.isOpen ? "Open Seat" : seat.name)
                            .foregroundStyle(seat.isOpen ? .secondary : .primary)
                    }
                } icon: {
                    Image(systemName: seat.isOpen ? "person.crop.circle.dashed" : "person.crop.circle.fill")
                        .foregroundStyle(seat.isOpen ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tint))
                }
            }
            HStack(spacing: 10) {
                ProgressView()
                Text(table.isReadyToStart ? "Starting the match…" : "Waiting for an opponent…")
                    .foregroundStyle(.secondary)
            }
            Button(isOwner ? "Close Table" : "Leave Table", role: .destructive, action: onLeave)
        } header: {
            Text(isOwner ? "Your Table" : "Joined Table")
        } footer: {
            Text("The match starts as soon as both seats are filled. Keep XMage open while you wait.")
        }
    }
}

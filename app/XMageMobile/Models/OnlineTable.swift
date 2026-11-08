import Foundation

nonisolated struct OnlineTable: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let owner: String
    let gameType: String
    let deckType: String
    let state: String
    let info: String
    let passworded: Bool
    let rated: Bool
    let skill: String?
    let createdAt: Double
    let freeSeats: Int
    let seats: [OnlineSeat]

    var format: String { Self.formatName(deckType) }

    var title: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "\(owner)’s table" : trimmed
    }

    var createdDate: Date? { createdAt > 0 ? Date(timeIntervalSince1970: createdAt / 1000) : nil }

    var isReadyToStart: Bool { state == "READY_TO_START" || state == "STARTING" }

    static func formatName(_ deckType: String) -> String {
        for prefix in ["Constructed - ", "Variant Magic - "] where deckType.hasPrefix(prefix) {
            return String(deckType.dropFirst(prefix.count))
        }
        return deckType
    }
}

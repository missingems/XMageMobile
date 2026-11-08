import Foundation

nonisolated struct DeckEntry: Identifiable, Hashable {
    let path: String

    var id: String { path }

    var name: String {
        let file = path.split(separator: "/").last.map(String.init) ?? path
        return file.hasSuffix(".dck") ? String(file.dropLast(4)) : file
    }

    var folder: String {
        let parts = path.split(separator: "/")
        return parts.count > 1 ? parts.dropLast().joined(separator: " › ") : "Decks"
    }

    static let myDecks = "My Decks"

    static func sections(_ paths: [String]) -> [(folder: String, decks: [DeckEntry])] {
        let entries = paths.map(DeckEntry.init(path:))
        let grouped = Dictionary(grouping: entries, by: \.folder)
        return grouped.keys.sorted { lhs, rhs in
            if (lhs == myDecks) != (rhs == myDecks) { return lhs == myDecks }
            if lhs.hasPrefix("AI") != rhs.hasPrefix("AI") { return lhs.hasPrefix("AI") }
            return lhs.localizedStandardCompare(rhs) == .orderedAscending
        }.map { ($0, grouped[$0] ?? []) }
    }
}

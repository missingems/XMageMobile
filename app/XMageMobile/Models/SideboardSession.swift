import Foundation

nonisolated struct SideboardSession: Identifiable, Hashable, Sendable {
    let id = UUID()
    let deckName: String
    let main: [DeckCard]
    let sideboard: [DeckCard]
    let deadline: Date
    let previousGame: GameResult?

    var mainCount: Int { main.reduce(0) { $0 + $1.count } }
}

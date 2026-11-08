import Foundation

struct ZoneRequest: Identifiable {
    let id = UUID()
    let title: String
    let cards: [Card]
}

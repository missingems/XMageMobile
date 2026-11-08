import SwiftUI

nonisolated enum ManaIdentity {
    private static let order = ["W", "U", "B", "R", "G"]
    private static let basics = ["Plains": "W", "Island": "U", "Swamp": "B", "Mountain": "R", "Forest": "G"]

    static func colors(of player: Player, in state: GameState) -> [String] {
        var cards = player.battlefield + player.graveyard + player.exile
        cards += state.stack.filter { $0.controllerId == player.id }
        if player.isYou {
            cards += state.hand
        }
        var found = Set<String>()
        for card in cards {
            found.formUnion(card.colors)
            if card.isLand, let basic = basics[card.name] {
                found.insert(basic)
            }
        }
        return order.filter(found.contains)
    }

    static func color(_ symbol: String) -> Color {
        switch symbol {
        case "W": Color(red: 0.90, green: 0.85, blue: 0.68)
        case "U": Color(red: 0.30, green: 0.52, blue: 0.84)
        case "B": Color(red: 0.36, green: 0.30, blue: 0.38)
        case "R": Color(red: 0.86, green: 0.34, blue: 0.24)
        case "G": Color(red: 0.28, green: 0.60, blue: 0.38)
        default: Color(red: 0.32, green: 0.36, blue: 0.46)
        }
    }
}

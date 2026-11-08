import Foundation

enum TableZone: String, Identifiable {
    case graveyard = "Graveyard"
    case exile = "Exile"
    case command = "Command Zone"
    case companion = "Companion"

    var id: String { rawValue }
}

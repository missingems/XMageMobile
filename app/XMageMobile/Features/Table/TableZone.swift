import Foundation

enum TableZone: String, Identifiable {
    case graveyard = "Graveyard"
    case exile = "Exile"
    case command = "Command Zone"

    var id: String { rawValue }
}

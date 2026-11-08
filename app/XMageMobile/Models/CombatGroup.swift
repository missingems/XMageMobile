import Foundation

nonisolated struct CombatGroup: Codable, Hashable, Sendable {
    var attackerIds: [String]
    var blockerIds: [String]
    var defenderId: String?
    var defenderName: String?
    var blocked: Bool
}

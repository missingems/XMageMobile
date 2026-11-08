import Foundation

nonisolated enum GameStep: String, CaseIterable, Sendable {
    case UNTAP, UPKEEP, DRAW, PRECOMBAT_MAIN, BEGIN_COMBAT, DECLARE_ATTACKERS, DECLARE_BLOCKERS
    case FIRST_COMBAT_DAMAGE, COMBAT_DAMAGE, END_COMBAT, POSTCOMBAT_MAIN, END_TURN, CLEANUP

    var title: String {
        switch self {
        case .UNTAP: "Untap"
        case .UPKEEP: "Upkeep"
        case .DRAW: "Draw"
        case .PRECOMBAT_MAIN: "Main 1"
        case .BEGIN_COMBAT: "Combat"
        case .DECLARE_ATTACKERS: "Attackers"
        case .DECLARE_BLOCKERS: "Blockers"
        case .FIRST_COMBAT_DAMAGE: "First Strike"
        case .COMBAT_DAMAGE: "Damage"
        case .END_COMBAT: "End Combat"
        case .POSTCOMBAT_MAIN: "Main 2"
        case .END_TURN: "End"
        case .CLEANUP: "Cleanup"
        }
    }

    var systemImage: String {
        switch self {
        case .UNTAP: "arrow.counterclockwise"
        case .UPKEEP: "sunrise"
        case .DRAW: "rectangle.stack"
        case .PRECOMBAT_MAIN, .POSTCOMBAT_MAIN: "sparkles"
        case .BEGIN_COMBAT, .END_COMBAT: "shield"
        case .DECLARE_ATTACKERS: "bolt"
        case .DECLARE_BLOCKERS: "shield.lefthalf.filled"
        case .FIRST_COMBAT_DAMAGE, .COMBAT_DAMAGE: "burst"
        case .END_TURN, .CLEANUP: "moon"
        }
    }

    var phrase: String {
        switch self {
        case .UNTAP: "untap step"
        case .UPKEEP: "upkeep"
        case .DRAW: "draw step"
        case .PRECOMBAT_MAIN: "first main phase"
        case .BEGIN_COMBAT: "beginning of combat"
        case .DECLARE_ATTACKERS: "attack step"
        case .DECLARE_BLOCKERS: "block step"
        case .FIRST_COMBAT_DAMAGE, .COMBAT_DAMAGE: "combat damage step"
        case .END_COMBAT: "end of combat"
        case .POSTCOMBAT_MAIN: "second main phase"
        case .END_TURN: "end step"
        case .CLEANUP: "cleanup step"
        }
    }

    var isMain: Bool { self == .PRECOMBAT_MAIN || self == .POSTCOMBAT_MAIN }

    static let strip: [GameStep] = [.UPKEEP, .DRAW, .PRECOMBAT_MAIN, .BEGIN_COMBAT, .DECLARE_ATTACKERS, .DECLARE_BLOCKERS, .COMBAT_DAMAGE, .POSTCOMBAT_MAIN, .END_TURN]

    var stripStep: GameStep {
        switch self {
        case .UNTAP: .UPKEEP
        case .FIRST_COMBAT_DAMAGE: .COMBAT_DAMAGE
        case .END_COMBAT: .COMBAT_DAMAGE
        case .CLEANUP: .END_TURN
        default: self
        }
    }
}

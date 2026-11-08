import Foundation

nonisolated enum PlayerAction: String, Sendable {
    case passUntilNextTurn = "PASS_PRIORITY_UNTIL_NEXT_TURN"
    case passUntilEndOfTurn = "PASS_PRIORITY_UNTIL_TURN_END_STEP"
    case passUntilNextMain = "PASS_PRIORITY_UNTIL_NEXT_MAIN_PHASE"
    case passUntilStackResolved = "PASS_PRIORITY_UNTIL_STACK_RESOLVED"
    case passUntilMyNextTurn = "PASS_PRIORITY_UNTIL_MY_NEXT_TURN"
    case cancelPasses = "PASS_PRIORITY_CANCEL_ALL_ACTIONS"
    case undo = "UNDO"
    case concede = "CONCEDE"
}

import Foundation

nonisolated enum MatchSheet: Identifiable, Hashable, Sendable {
    case result(GameResult)
    case sideboard(SideboardSession)
    case waitingForNextGame

    var id: String {
        switch self {
        case let .result(result): "result-\(result.id)"
        case let .sideboard(session): "sideboard-\(session.id)"
        case .waitingForNextGame: "waiting"
        }
    }
}

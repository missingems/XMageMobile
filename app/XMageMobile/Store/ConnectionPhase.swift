import Foundation

nonisolated enum ConnectionPhase: Equatable, Sendable {
    case idle
    case reachingBridge
    case loggingIn
    case lobby
    case startingGame
    case playing
    case failed(String)

    var isBusy: Bool {
        switch self {
        case .reachingBridge, .loggingIn, .startingGame: true
        default: false
        }
    }

    var isConnected: Bool {
        switch self {
        case .lobby, .startingGame, .playing: true
        default: false
        }
    }
}

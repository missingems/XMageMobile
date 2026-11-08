import Foundation

nonisolated enum BridgeEvent: Sendable {
    case message(BridgeMessage)
    case closed(String?)
}

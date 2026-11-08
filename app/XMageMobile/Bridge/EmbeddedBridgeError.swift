import Foundation

nonisolated enum EmbeddedBridgeError: LocalizedError {
    case notRunning

    var errorDescription: String? {
        "The built-in XMage engine isn't running."
    }
}

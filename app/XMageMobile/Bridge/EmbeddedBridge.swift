import Foundation

final class EmbeddedBridge: BridgeTransport {
    private let decksPath: String

    init(decksPath: String) {
        self.decksPath = decksPath
    }

    func events() -> AsyncStream<BridgeEvent> {
        let engine = EmbeddedEngine.shared
        let decksPath = decksPath
        return AsyncStream { continuation in
            engine.control.async {
                guard engine.isAvailable, engine.open(decksPath: decksPath, into: continuation) else {
                    continuation.yield(.closed("The built-in XMage engine couldn't start."))
                    continuation.finish()
                    return
                }
            }
        }
    }

    func send(_ request: BridgeRequest) async throws {
        let text = try request.encoded()
        guard EmbeddedEngine.shared.send(text) else {
            throw EmbeddedBridgeError.notRunning
        }
    }

    func close() {
        let engine = EmbeddedEngine.shared
        engine.control.async {
            engine.close()
        }
    }
}

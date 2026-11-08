import Foundation

protocol BridgeTransport: AnyObject {
    func events() -> AsyncStream<BridgeEvent>
    func send(_ request: BridgeRequest) async throws
    func close()
}

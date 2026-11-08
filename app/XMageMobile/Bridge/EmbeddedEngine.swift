import Foundation
import os
import XMageBridge

nonisolated final class EmbeddedEngine: @unchecked Sendable {
    static let shared = EmbeddedEngine()

    let control = DispatchQueue(label: "xmage-bridge-control", qos: .userInitiated)

    private let isolate: OpaquePointer?
    private let sink = OSAllocatedUnfairLock<AsyncStream<BridgeEvent>.Continuation?>(initialState: nil)
    private let pollerStarted = OSAllocatedUnfairLock(initialState: false)

    private init() {
        var isolate: OpaquePointer?
        var thread: OpaquePointer?
        self.isolate = graal_create_isolate(nil, &isolate, &thread) == 0 ? isolate : nil
    }

    var isAvailable: Bool { isolate != nil }

    func open(decksPath: String, into continuation: AsyncStream<BridgeEvent>.Continuation) -> Bool {
        guard let thread = currentThread() else { return false }
        sink.withLock { $0 = continuation }
        startPollerIfNeeded()
        let result = decksPath.withCString { xmb_open(thread, UnsafeMutablePointer(mutating: $0)) }
        return result == 0
    }

    func send(_ text: String) -> Bool {
        guard let thread = currentThread() else { return false }
        return text.withCString { xmb_send(thread, UnsafeMutablePointer(mutating: $0)) } == 0
    }

    func close() {
        sink.withLock { $0 = nil }
        guard let thread = currentThread() else { return }
        xmb_close(thread)
    }

    private func currentThread() -> OpaquePointer? {
        guard let isolate else { return nil }
        if let thread = graal_get_current_thread(isolate) {
            return thread
        }
        var thread: OpaquePointer?
        return graal_attach_thread(isolate, &thread) == 0 ? thread : nil
    }

    private func startPollerIfNeeded() {
        let shouldStart = pollerStarted.withLock { started in
            defer { started = true }
            return !started
        }
        guard shouldStart else { return }
        let poller = Thread { [self] in poll() }
        poller.name = "xmage-bridge-poller"
        poller.qualityOfService = .userInitiated
        poller.start()
    }

    private func poll() {
        guard let thread = currentThread() else { return }
        let decoder = JSONDecoder()
        while true {
            guard let pointer = xmb_poll(thread, 500) else { continue }
            let data = Data(bytes: pointer, count: strlen(pointer))
            xmb_free(thread, pointer)
            let event: BridgeEvent
            do {
                event = .message(try decoder.decode(BridgeMessage.self, from: data))
            } catch {
                event = .message(.error("Couldn't read a bridge message: \(error.localizedDescription)"))
            }
            _ = sink.withLock { $0?.yield(event) }
        }
    }
}

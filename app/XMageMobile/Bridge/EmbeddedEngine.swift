import Foundation
import os
import XMageBridge

nonisolated final class EmbeddedEngine: @unchecked Sendable {
    static let shared = EmbeddedEngine()

    let control = DispatchQueue(label: "xmage-bridge-control", qos: .userInitiated)

    private static let log = Logger(subsystem: "com.missingems.XMageMobile", category: "engine")

    private let isolate: OpaquePointer?
    private(set) var startupCode: Int32 = 0
    private let sink = OSAllocatedUnfairLock<AsyncStream<BridgeEvent>.Continuation?>(initialState: nil)
    private let pollerStarted = OSAllocatedUnfairLock(initialState: false)

    private init() {
        var created: OpaquePointer?
        var code: Int32 = -1
        for gigabytes in [2, 1] as [UInt] {
            var params = graal_create_isolate_params_t()
            params.version = Int32(__graal_create_isolate_params_version)
            params.reserved_address_space_size = gigabytes << 30
            var isolate: OpaquePointer?
            var thread: OpaquePointer?
            code = graal_create_isolate(&params, &isolate, &thread)
            if code == 0 {
                created = isolate
                break
            }
        }
        if code != 0 {
            Self.log.error("graal_create_isolate failed with \(code)")
        }
        startupCode = code
        isolate = created
    }

    var isAvailable: Bool { isolate != nil }

    func open(decksPath: String, into continuation: AsyncStream<BridgeEvent>.Continuation) -> Bool {
        guard let thread = currentThread() else { return false }
        sink.withLock { $0 = continuation }
        startPollerIfNeeded()
        let result = decksPath.withCString { xmb_open(thread, UnsafeMutablePointer(mutating: $0)) }
        if result != 0 {
            Self.log.error("xmb_open failed with \(result)")
        }
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

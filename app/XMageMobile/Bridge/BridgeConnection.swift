import Foundation

final class BridgeConnection {
    enum Event: Sendable {
        case message(BridgeMessage)
        case closed(String?)
    }

    private let task: URLSessionWebSocketTask
    private let decoder = JSONDecoder()

    init(url: URL) {
        task = URLSession.shared.webSocketTask(with: url)
        task.maximumMessageSize = 16 * 1024 * 1024
    }

    func events() -> AsyncStream<Event> {
        task.resume()
        let task = task
        let decoder = decoder
        return AsyncStream { continuation in
            let reader = Task {
                while !Task.isCancelled {
                    do {
                        let frame = try await task.receive()
                        let data: Data = switch frame {
                        case let .string(text): Data(text.utf8)
                        case let .data(data): data
                        @unknown default: Data()
                        }
                        do {
                            continuation.yield(.message(try decoder.decode(BridgeMessage.self, from: data)))
                        } catch {
                            continuation.yield(.message(.error("Couldn't read a bridge message: \(error.localizedDescription)")))
                        }
                    } catch {
                        continuation.yield(.closed(error.localizedDescription))
                        continuation.finish()
                        return
                    }
                }
            }
            continuation.onTermination = { _ in reader.cancel() }
        }
    }

    func send(_ request: BridgeRequest) async throws {
        try await task.send(.string(request.encoded()))
    }

    func close() {
        task.cancel(with: .normalClosure, reason: nil)
    }
}

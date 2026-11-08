import Foundation

nonisolated struct ServerSettings: Hashable, Sendable {
    var bridgeHost: String
    var bridgePort: Int
    var serverHost: String
    var serverPort: Int
    var username: String
    var usesMacBridge = false

    var bridgeURL: URL? {
        var components = URLComponents()
        components.scheme = "ws"
        components.host = bridgeHost.trimmingCharacters(in: .whitespaces)
        components.port = bridgePort
        components.path = "/ws"
        return components.url
    }
}

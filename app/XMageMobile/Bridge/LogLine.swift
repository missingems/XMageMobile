import Foundation

nonisolated struct LogLine: Decodable, Identifiable, Hashable, Sendable {
    var id = UUID()
    let text: String
    var kind: String?
    var turnInfo: String?
    var user: String?

    enum CodingKeys: String, CodingKey {
        case text, kind, turnInfo, user
    }

    var isGameLog: Bool { kind == "GAME" }
}

import Foundation

nonisolated struct PromptChoice: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let label: String
}

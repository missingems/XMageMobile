import Foundation

nonisolated struct Prompt: Codable, Identifiable, Hashable, Sendable {
    enum Kind: String, Codable, Sendable {
        case select, target, ask, mana, xmana, amount, multiAmount, choice, ability, pile, unknown

        init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Kind(rawValue: raw) ?? .unknown
        }
    }

    var id = UUID()
    let kind: Kind
    var gameId: String?
    var message: String
    var required: Bool?
    var targetIds: [String]?
    var cards: [Card]?
    var choices: [PromptChoice]?
    var min: Int?
    var max: Int?
    var doneLabel: String?
    var yesLabel: String?
    var noLabel: String?
    var specialLabel: String?
    var rows: [AmountRow]?
    var pile1: [Card]?
    var pile2: [Card]?

    enum CodingKeys: String, CodingKey {
        case kind, gameId, message, required, targetIds, cards, choices, min, max
        case doneLabel, yesLabel, noLabel, specialLabel, rows, pile1, pile2
    }

    var needsSheet: Bool {
        switch kind {
        case .choice, .ability, .amount, .multiAmount, .pile: true
        case .target: !(cards ?? []).isEmpty
        default: false
        }
    }

    var isPriority: Bool {
        kind == .select && (message.localizedStandardContains("Play spells and abilities")
            || message.localizedStandardContains("Play instants and activated abilities"))
    }
}

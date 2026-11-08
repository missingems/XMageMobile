import Foundation

nonisolated struct Card: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    var set: String?
    var number: String?
    var manaCost: String?
    var manaValue: Int?
    var typeLine: String?
    var types: [String] = []
    var colors: [String] = []
    var rules: [String] = []
    var power: String?
    var toughness: String?
    var loyalty: String?
    var defense: String?
    var isToken = false
    var isAbility = false
    var faceDown = false
    var rarity: String?
    var counters: [Counter] = []
    var playable = false
    var choosable = false
    var selected = false
    var controllerId: String?
    var targetIds: [String]?
    var tapped: Bool?
    var damage: Int?
    var summoningSick: Bool?
    var attachedTo: String?
    var attachmentIds: [String]?

    var isLand: Bool { types.contains("Land") }
    var isCreature: Bool { types.contains("Creature") }
    var isTapped: Bool { tapped ?? false }
    var isActionable: Bool { playable || choosable }
    var showsPowerToughness: Bool { power != nil && toughness != nil && (isCreature || typeLine?.localizedStandardContains("Vehicle") == true) }

    enum CodingKeys: String, CodingKey {
        case id, name, set, number, manaCost, manaValue, typeLine, types, colors, rules, power, toughness, loyalty, defense
        case isToken, isAbility, faceDown, rarity, counters, playable, choosable, selected, controllerId, targetIds
        case tapped, damage, summoningSick, attachedTo, attachmentIds
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        set = try c.decodeIfPresent(String.self, forKey: .set)
        number = try c.decodeIfPresent(String.self, forKey: .number)
        manaCost = try c.decodeIfPresent(String.self, forKey: .manaCost)
        manaValue = try c.decodeIfPresent(Int.self, forKey: .manaValue)
        typeLine = try c.decodeIfPresent(String.self, forKey: .typeLine)
        types = try c.decodeIfPresent([String].self, forKey: .types) ?? []
        colors = try c.decodeIfPresent([String].self, forKey: .colors) ?? []
        rules = try c.decodeIfPresent([String].self, forKey: .rules) ?? []
        power = try c.decodeIfPresent(String.self, forKey: .power)
        toughness = try c.decodeIfPresent(String.self, forKey: .toughness)
        loyalty = try c.decodeIfPresent(String.self, forKey: .loyalty)
        defense = try c.decodeIfPresent(String.self, forKey: .defense)
        isToken = try c.decodeIfPresent(Bool.self, forKey: .isToken) ?? false
        isAbility = try c.decodeIfPresent(Bool.self, forKey: .isAbility) ?? false
        faceDown = try c.decodeIfPresent(Bool.self, forKey: .faceDown) ?? false
        rarity = try c.decodeIfPresent(String.self, forKey: .rarity)
        counters = try c.decodeIfPresent([Counter].self, forKey: .counters) ?? []
        playable = try c.decodeIfPresent(Bool.self, forKey: .playable) ?? false
        choosable = try c.decodeIfPresent(Bool.self, forKey: .choosable) ?? false
        selected = try c.decodeIfPresent(Bool.self, forKey: .selected) ?? false
        controllerId = try c.decodeIfPresent(String.self, forKey: .controllerId)
        targetIds = try c.decodeIfPresent([String].self, forKey: .targetIds)
        tapped = try c.decodeIfPresent(Bool.self, forKey: .tapped)
        damage = try c.decodeIfPresent(Int.self, forKey: .damage)
        summoningSick = try c.decodeIfPresent(Bool.self, forKey: .summoningSick)
        attachedTo = try c.decodeIfPresent(String.self, forKey: .attachedTo)
        attachmentIds = try c.decodeIfPresent([String].self, forKey: .attachmentIds)
    }
}

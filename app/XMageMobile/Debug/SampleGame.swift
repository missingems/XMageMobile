#if DEBUG
import Foundation

enum SampleGame {
    static let meId = "sample-me"
    static let opponentId = "sample-opponent"

    static var prompt: Prompt {
        Prompt(kind: .select, message: "Play instants and activated abilities.")
    }

    static var state: GameState {
        GameState(gameId: "sample", turn: 5, phase: "PRECOMBAT_MAIN", step: "PRECOMBAT_MAIN",
                  activePlayerId: opponentId, isPlayer: true, priorityPlayerId: meId,
                  players: [me, opponent], hand: hand, stack: stack, combat: [], revealed: nil)
    }

    private static var me: Player {
        let battlefield: [Card] = [
            card("m-sheoldred", "Sheoldred, the Apocalypse", ["Creature"], ["B"], pt: ("4", "5"), rules: ["Deathtouch"]),
            card("m-dauthi", "Dauthi Voidwalker", ["Creature"], ["B"], pt: ("3", "2"), rules: ["Shadow"]),
            card("m-bowmasters", "Orcish Bowmasters", ["Creature"], ["B"], pt: ("1", "1"), tapped: true),
            card("m-bloodghast", "Bloodghast", ["Creature"], ["B"], pt: ("2", "1"), sick: true),
            card("m-necro", "Necropotence", ["Enchantment"], ["B"]),
            card("m-swamp1", "Swamp", ["Land"]),
            card("m-swamp2", "Swamp", ["Land"]),
            card("m-swamp3", "Swamp", ["Land"]),
            card("m-urborg", "Urborg, Tomb of Yawgmoth", ["Land"]),
            card("m-castle", "Castle Locthwain", ["Land"], tapped: true),
        ]
        return Player(id: meId, name: "Planeswalker", life: 18, libraryCount: 41, handCount: 9,
                      isYou: true, isActive: false, hasPriority: true, hasLeft: false, isMonarch: false,
                      choosable: false, manaPool: ManaPool(), counters: [], battlefield: battlefield,
                      graveyard: [card("m-g1", "Fatal Push", ["Instant"], ["B"]), card("m-g2", "Thoughtseize", ["Sorcery"], ["B"])],
                      exile: [card("m-x1", "Lightning Helix", ["Instant"], ["R", "W"])],
                      command: [], companion: [])
    }

    private static var opponent: Player {
        var pride = card("o-pride", "Ocelot Pride", ["Creature"], ["W"], pt: ("2", "2"), rules: ["First strike, lifelink"])
        pride.counters = [Counter(name: "+1/+1", count: 1)]
        var chandra = card("o-chandra", "Chandra, Torch of Defiance", ["Planeswalker"], ["R"])
        chandra.loyalty = "4"
        let battlefield: [Card] = [
            card("o-ragavan", "Ragavan, Nimble Pilferer", ["Creature"], ["R"], pt: ("2", "1"), tapped: true, rules: ["Dash {1}{R}"]),
            card("o-guide", "Guide of Souls", ["Creature"], ["W"], pt: ("1", "2")),
            card("o-angel", "Resplendent Angel", ["Creature"], ["W"], pt: ("3", "3"), rules: ["Flying"]),
            pride,
            chandra,
            card("o-foundry", "Sacred Foundry", ["Land"], tapped: true),
            card("o-vantage", "Inspiring Vantage", ["Land"], tapped: true),
            card("o-mountain1", "Mountain", ["Land"], tapped: true),
            card("o-mountain2", "Mountain", ["Land"]),
            card("o-plains", "Plains", ["Land"]),
        ]
        return Player(id: opponentId, name: "Opponent", life: 14, libraryCount: 44, handCount: 4,
                      isYou: false, isActive: true, hasPriority: false, hasLeft: false, isMonarch: false,
                      choosable: false, manaPool: ManaPool(), counters: [], battlefield: battlefield,
                      graveyard: [card("o-g1", "Boros Charm", ["Instant"], ["R", "W"]), card("o-g2", "Lightning Bolt", ["Instant"], ["R"])],
                      exile: [], command: [], companion: [])
    }

    private static var hand: [Card] {
        [
            card("h-push", "Fatal Push", ["Instant"], ["B"], playable: true),
            card("h-edict", "Sheoldred's Edict", ["Instant"], ["B"], playable: true),
            card("h-seize", "Thoughtseize", ["Sorcery"], ["B"]),
            card("h-meathook", "The Meathook Massacre", ["Enchantment"], ["B"]),
            card("h-liliana", "Liliana of the Veil", ["Planeswalker"], ["B"]),
            card("h-swamp", "Swamp", ["Land"]),
            card("h-bowmasters", "Orcish Bowmasters", ["Creature"], ["B"], pt: ("1", "1"), playable: true),
            card("h-grief", "Grief", ["Creature"], ["B"], pt: ("3", "2")),
            card("h-tomb", "Takenuma, Abandoned Mire", ["Land"]),
        ]
    }

    private static var stack: [Card] {
        var bolt = card("s-bolt", "Lightning Bolt", ["Instant"], ["R"])
        bolt.controllerId = opponentId
        bolt.targetIds = ["m-sheoldred"]
        return [bolt]
    }

    private static func card(_ id: String, _ name: String, _ types: [String], _ colors: [String] = [],
                             pt: (String, String)? = nil, tapped: Bool = false, sick: Bool = false,
                             playable: Bool = false, rules: [String] = []) -> Card {
        var card = Card(id: id, name: name)
        card.types = types
        card.colors = colors
        card.typeLine = types.joined(separator: " ")
        card.power = pt?.0
        card.toughness = pt?.1
        card.tapped = tapped
        card.summoningSick = sick
        card.playable = playable
        card.rules = rules
        return card
    }
}
#endif

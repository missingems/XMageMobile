import Foundation

nonisolated enum Keyword: String, CaseIterable, Sendable {
    case flying, reach, firstStrike, doubleStrike, trample, haste, vigilance
    case deathtouch, lifelink, menace, hexproof, ward, indestructible, defender

    var title: String {
        switch self {
        case .flying: "Flying"
        case .reach: "Reach"
        case .firstStrike: "First strike"
        case .doubleStrike: "Double strike"
        case .trample: "Trample"
        case .haste: "Haste"
        case .vigilance: "Vigilance"
        case .deathtouch: "Deathtouch"
        case .lifelink: "Lifelink"
        case .menace: "Menace"
        case .hexproof: "Hexproof"
        case .ward: "Ward"
        case .indestructible: "Indestructible"
        case .defender: "Defender"
        }
    }

    var systemImage: String {
        switch self {
        case .flying: "bird.fill"
        case .reach: "arrow.up.to.line"
        case .firstStrike: "chevron.right"
        case .doubleStrike: "chevron.right.2"
        case .trample: "shoeprints.fill"
        case .haste: "hare.fill"
        case .vigilance: "eye.fill"
        case .deathtouch: "drop.fill"
        case .lifelink: "heart.fill"
        case .menace: "exclamationmark.triangle.fill"
        case .hexproof: "shield.lefthalf.filled"
        case .ward: "shield.checkered"
        case .indestructible: "diamond.fill"
        case .defender: "hand.raised.fill"
        }
    }

    static func parse(_ rules: [String]) -> [Keyword] {
        var found: [Keyword] = []
        for line in rules {
            for part in line.split(separator: ",") {
                let phrase = part.trimmingCharacters(in: .whitespaces).lowercased()
                for keyword in allCases where !found.contains(keyword) {
                    let name = keyword.title.lowercased()
                    if phrase == name || phrase.hasPrefix(name + " ") || phrase.hasPrefix(name + "—") || phrase.hasPrefix(name + " (") {
                        found.append(keyword)
                    }
                }
            }
        }
        return found
    }
}

import Foundation

nonisolated struct ScryfallCard: Decodable, Sendable {
    struct Images: Decodable, Sendable {
        let normal: URL?
        let artCrop: URL?

        enum CodingKeys: String, CodingKey {
            case normal
            case artCrop = "art_crop"
        }

        func url(for variant: CardImageVariant) -> URL? {
            switch variant {
            case .normal: normal
            case .artCrop: artCrop ?? normal
            }
        }
    }

    struct Face: Decodable, Sendable {
        let name: String
        let imageURIs: Images?

        enum CodingKeys: String, CodingKey {
            case name
            case imageURIs = "image_uris"
        }
    }

    let imageURIs: Images?
    let cardFaces: [Face]?

    enum CodingKeys: String, CodingKey {
        case imageURIs = "image_uris"
        case cardFaces = "card_faces"
    }

    func imageURL(forFaceNamed name: String, variant: CardImageVariant = .normal) -> URL? {
        let faces = (cardFaces ?? []).filter { $0.imageURIs?.url(for: variant) != nil }
        if let face = faces.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            return face.imageURIs?.url(for: variant)
        }
        return imageURIs?.url(for: variant) ?? faces.first?.imageURIs?.url(for: variant)
    }
}

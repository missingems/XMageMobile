import Foundation

nonisolated struct ScryfallCard: Decodable, Sendable {
    struct Images: Decodable, Sendable {
        let normal: URL?
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

    func imageURL(forFaceNamed name: String) -> URL? {
        let faces = (cardFaces ?? []).filter { $0.imageURIs?.normal != nil }
        if let face = faces.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            return face.imageURIs?.normal
        }
        return imageURIs?.normal ?? faces.first?.imageURIs?.normal
    }
}

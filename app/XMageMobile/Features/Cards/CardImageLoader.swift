import SwiftUI

actor CardImageLoader {
    static let shared = CardImageLoader()

    private let session: URLSession
    private let memory = NSCache<NSString, UIImage>()
    private var inFlight: [String: Task<UIImage?, Never>] = [:]
    private var cards: [URL: ScryfallCard] = [:]
    private var cardLookups: [URL: Task<ScryfallCard?, Never>] = [:]
    private var misses: Set<String> = []
    private var nextSlot = ContinuousClock.now
    private var cardBackRetryAfter: ContinuousClock.Instant?

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(memoryCapacity: 64 * 1024 * 1024, diskCapacity: 768 * 1024 * 1024)
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.httpAdditionalHeaders = ["User-Agent": "XMageMobile/0.1", "Accept": "image/*,*/*"]
        session = URLSession(configuration: configuration)
        memory.countLimit = 300
    }

    func image(set: String?, number: String?, name: String, variant: CardImageVariant = .normal) async -> UIImage? {
        let key = "\(variant.rawValue)/\(set ?? "")/\(number ?? "")/\(name)"
        if let cached = memory.object(forKey: key as NSString) { return cached }
        if misses.contains(key) { return nil }
        if let running = inFlight[key] { return await running.value }

        let urls = Self.candidateURLs(set: set, number: number, name: name)
        let task = Task { await self.fetchFirst(urls, faceName: name, variant: variant) }
        inFlight[key] = task
        let image = await task.value
        inFlight[key] = nil
        if let image {
            memory.setObject(image, forKey: key as NSString)
        } else {
            misses.insert(key)
        }
        return image
    }

    func cardBack() async -> UIImage? {
        let key = "card-back"
        if let cached = memory.object(forKey: key as NSString) { return cached }
        if let running = inFlight[key] { return await running.value }
        if let retry = cardBackRetryAfter, ContinuousClock.now < retry { return nil }
        let task = Task { await self.fetch(Self.cardBackURL) }
        inFlight[key] = task
        let image = await task.value
        inFlight[key] = nil
        if let image {
            memory.setObject(image, forKey: key as NSString)
            cardBackRetryAfter = nil
        } else {
            cardBackRetryAfter = .now + .seconds(60)
        }
        return image
    }

    private static let cardBackURL = URL(string: "https://backs.scryfall.io/normal/0/a/0aeebaf5-8c7d-4636-9e82-8c27447861f7.jpg")!

    private func fetchFirst(_ urls: [URL], faceName: String, variant: CardImageVariant) async -> UIImage? {
        for url in urls {
            guard let card = await lookup(url), let imageURL = card.imageURL(forFaceNamed: faceName, variant: variant) else { continue }
            if let image = await fetch(imageURL) { return image }
        }
        return nil
    }

    private func lookup(_ url: URL) async -> ScryfallCard? {
        if let card = cards[url] { return card }
        if let running = cardLookups[url] { return await running.value }
        let task = Task { await self.loadCard(url) }
        cardLookups[url] = task
        let card = await task.value
        cardLookups[url] = nil
        if let card { cards[url] = card }
        return card
    }

    private func loadCard(_ url: URL) async -> ScryfallCard? {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let cached = session.configuration.urlCache?.cachedResponse(for: request),
           let card = try? JSONDecoder().decode(ScryfallCard.self, from: cached.data) {
            return card
        }
        await waitForSlot()
        guard let (data, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        return try? JSONDecoder().decode(ScryfallCard.self, from: data)
    }

    private func fetch(_ url: URL) async -> UIImage? {
        let request = URLRequest(url: url)
        if let cached = session.configuration.urlCache?.cachedResponse(for: request),
           let image = UIImage(data: cached.data) {
            return await image.byPreparingForDisplay() ?? image
        }
        if url.host() == "api.scryfall.com" {
            await waitForSlot()
        }
        guard let (data, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let image = UIImage(data: data) else { return nil }
        return await image.byPreparingForDisplay() ?? image
    }

    private func waitForSlot() async {
        let now = ContinuousClock.now
        let slot = max(now, nextSlot)
        nextSlot = slot + .milliseconds(110)
        if slot > now {
            try? await Task.sleep(until: slot)
        }
    }

    private static func candidateURLs(set: String?, number: String?, name: String) -> [URL] {
        var urls: [URL] = []
        if let set, let number, !set.isEmpty, !number.isEmpty {
            var components = URLComponents(string: "https://api.scryfall.com")
            components?.path = "/cards/\(set.lowercased())/\(number.lowercased())"
            if let url = components?.url { urls.append(url) }
        }
        let face = name.components(separatedBy: " // ").first ?? name
        var named = URLComponents(string: "https://api.scryfall.com/cards/named")
        named?.queryItems = [.init(name: "exact", value: face)]
        if let url = named?.url { urls.append(url) }
        return urls
    }
}

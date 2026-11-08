import SwiftUI

actor CardImageLoader {
    static let shared = CardImageLoader()

    private let session: URLSession
    private let memory = NSCache<NSString, UIImage>()
    private var inFlight: [String: Task<UIImage?, Never>] = [:]
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

    func image(set: String?, number: String?, name: String) async -> UIImage? {
        let key = "\(set ?? "")/\(number ?? "")/\(name)"
        if let cached = memory.object(forKey: key as NSString) { return cached }
        if misses.contains(key) { return nil }
        if let running = inFlight[key] { return await running.value }

        let urls = Self.candidateURLs(set: set, number: number, name: name)
        let task = Task { await self.fetchFirst(urls) }
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

    private func fetchFirst(_ urls: [URL]) async -> UIImage? {
        for url in urls {
            if let image = await fetch(url) { return image }
        }
        return nil
    }

    private func fetch(_ url: URL) async -> UIImage? {
        let request = URLRequest(url: url)
        if let cached = session.configuration.urlCache?.cachedResponse(for: request),
           let image = UIImage(data: cached.data) {
            return await image.byPreparingForDisplay() ?? image
        }
        await waitForSlot()
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
            components?.queryItems = [.init(name: "format", value: "image"), .init(name: "version", value: "normal")]
            if let url = components?.url { urls.append(url) }
        }
        let face = name.components(separatedBy: " // ").first ?? name
        var named = URLComponents(string: "https://api.scryfall.com/cards/named")
        named?.queryItems = [.init(name: "exact", value: face), .init(name: "format", value: "image"), .init(name: "version", value: "normal")]
        if let url = named?.url { urls.append(url) }
        return urls
    }
}

import Foundation

/// The six independently hosted TYZX wikis. Deliberately separate from WMFProject:
/// a school wiki is not a Wikipedia language edition and must not enter WMF auth or analytics.
public enum WMFTianyiSite: String, CaseIterable, Codable, Identifiable, Sendable {
    case zh, en, fr, ja, ko, lzh
    public var id: String { rawValue }
    public var name: String {
        switch self {
        case .zh: "中文"
        case .en: "English"
        case .fr: "Français"
        case .ja: "日本語"
        case .ko: "한국어"
        case .lzh: "文言"
        }
    }
    public var host: String { "\(rawValue)-wiki.tyzx.org" }
    public var baseURL: URL { URL(string: "https://\(host)")! }
    public func pageURL(_ title: String) -> URL {
        var parts = URLComponents(url: baseURL.appendingPathComponent("index.php"), resolvingAgainstBaseURL: false)!
        parts.queryItems = [URLQueryItem(name: "title", value: title), URLQueryItem(name: "useskin", value: "minerva")]
        return parts.url!
    }
    public func apiURL(_ parameters: [String: String]) -> URL {
        var parts = URLComponents(url: baseURL.appendingPathComponent("api.php"), resolvingAgainstBaseURL: false)!
        let values = parameters.merging(["format": "json", "formatversion": "2"]) { _, new in new }
        parts.queryItems = values.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        return parts.url!
    }
    public static func matching(_ url: URL) -> Self? {
        guard url.scheme == "https", url.user == nil, url.password == nil,
              url.port == nil || url.port == 443 else { return nil }
        if url.host?.lowercased() == "wiki.tyzx.org" { return .zh }
        return allCases.first { $0.host == url.host?.lowercased() }
    }
    public func title(in url: URL) -> String? {
        guard Self.matching(url) == self else { return nil }
        if url.path.hasPrefix("/wiki/") { return String(url.path.dropFirst(6)).replacingOccurrences(of: "_", with: " ") }
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "title" }?.value
    }
}

public struct WMFTianyiPage: Codable, Identifiable, Hashable, Sendable {
    public var title: String
    public var site: WMFTianyiSite
    public var date: Date
    public var id: String { "\(site.rawValue):\(title)" }
    public var url: URL { site.pageURL(title) }
    public init(title: String, site: WMFTianyiSite, date: Date = Date()) {
        self.title = title; self.site = site; self.date = date
    }
}
public struct WMFTianyiSearchHit: Decodable, Identifiable, Sendable {
    public let pageid: Int
    public let title: String
    public let snippet: String
    public var id: Int { pageid }
}
public struct WMFTianyiChange: Codable, Identifiable, Sendable {
    public let rcid: Int
    public let title: String
    public let timestamp: String
    public var id: Int { rcid }
}
public struct WMFTianyiArticle: Codable, Sendable {
    public struct LanguageLink: Codable, Sendable {
        public let lang: String
        public let title: String
        public let url: URL
    }
    public var langlinks: [LanguageLink]? = nil
    /// Ignore links outside this wiki family, even if a server advertises a familiar language code.
    public var translatedPages: [WMFTianyiPage] {
        (langlinks ?? []).compactMap { link in
            guard let site = WMFTianyiSite(rawValue: link.lang),
                  WMFTianyiSite.matching(link.url) == site else { return nil }
            return WMFTianyiPage(title: link.title, site: site)
        }
    }
    public struct Section: Codable, Identifiable, Sendable {
        public let index: String
        public let line: String
        public let anchor: String
        public var id: String { index }
    }
    public let title: String
    public let pageid: Int
    public let revid: Int
    public let text: String
    public let sections: [Section]
}
private struct TianyiResponse: Decodable, Sendable {
    struct Query: Decodable, Sendable {
        var search: [WMFTianyiSearchHit]?
        var recentchanges: [WMFTianyiChange]?
        var random: [RandomPage]?
    }
    struct RandomPage: Decodable, Sendable { let title: String }
    struct Failure: Decodable, Sendable { let code: String; let info: String }
    var query: Query?
    var parse: WMFTianyiArticle?
    var error: Failure?
}
public enum WMFTianyiError: LocalizedError, Sendable {
    case api(String), invalidResponse, missingPage
    public var errorDescription: String? {
        switch self {
        case .api(let message): message
        case .invalidResponse: "站点返回了无法识别的数据，请重试或打开原网页。"
        case .missingPage: "此语言站点暂无此词条。"
        }
    }
}

/// Reuses Wikipedia iOS's request builder, HTTP validation and cancellable WMFService.
/// No Wikimedia recommendation, metrics, donation, CentralAuth or PCS endpoints are used.
public struct WMFTianyiDataController: Sendable {
    public static let shared = WMFTianyiDataController()
    private let service: any WMFService
    public init(service: any WMFService = WMFBasicService()) { self.service = service }
    private func fetch(site: WMFTianyiSite, parameters: [String: String]) async throws -> TianyiResponse {
        try Task.checkCancellation()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-TianyiOffline") { throw URLError(.notConnectedToInternet) }
        #endif
        let cancellation = WMFRequestCancellation()
        // The request is created inside the continuation: its legacy Any-valued fields
        // never cross an actor boundary. The decoded response is a Sendable value.
        let response: TianyiResponse = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let request = WMFBasicServiceRequest(url: site.apiURL(parameters), method: .GET, acceptType: .json)
                let task = service.performCancellableDecodableGET(request: request) { (result: Result<TianyiResponse, Error>) in
                    continuation.resume(with: result)
                }
                cancellation.setTask(task)
            }
        } onCancel: { cancellation.cancel() }
        try Task.checkCancellation()
        if let error = response.error {
            if error.code == "missingtitle" { throw WMFTianyiError.missingPage }
            throw WMFTianyiError.api(error.info)
        }
        return response
    }
    public func search(_ term: String, site: WMFTianyiSite) async throws -> [WMFTianyiSearchHit] {
        let response = try await fetch(site: site, parameters: ["action": "query", "list": "search", "srsearch": term, "srnamespace": "0", "srlimit": "30"])
        guard let hits = response.query?.search else { throw WMFTianyiError.invalidResponse }
        return hits
    }
    public func recent(site: WMFTianyiSite) async throws -> [WMFTianyiChange] {
        let response = try await fetch(site: site, parameters: ["action": "query", "list": "recentchanges", "rcnamespace": "0", "rctype": "edit|new", "rcshow": "!bot", "rcprop": "title|timestamp|ids", "rclimit": "500", "rcdir": "older"])
        guard let changes = response.query?.recentchanges else { throw WMFTianyiError.invalidResponse }
        return Self.latestUniqueChanges(changes)
    }
    public static func latestUniqueChanges(_ changes: [WMFTianyiChange]) -> [WMFTianyiChange] {
        var titles = Set<String>()
        return Array(changes.sorted { $0.timestamp > $1.timestamp }.filter { titles.insert($0.title).inserted }.prefix(5))
    }
    public func random(site: WMFTianyiSite) async throws -> String {
        let response = try await fetch(site: site, parameters: ["action": "query", "list": "random", "rnnamespace": "0", "rnlimit": "1"])
        guard let title = response.query?.random?.first?.title else { throw WMFTianyiError.invalidResponse }
        return title
    }
    public func article(_ page: WMFTianyiPage) async throws -> WMFTianyiArticle {
        let response = try await fetch(site: page.site, parameters: ["action": "parse", "page": page.title, "prop": "text|sections|revid|langlinks", "redirects": "1", "disableeditsection": "1"])
        guard let article = response.parse else { throw WMFTianyiError.invalidResponse }
        return article
    }
}

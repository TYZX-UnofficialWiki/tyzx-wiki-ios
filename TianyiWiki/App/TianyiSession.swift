import Foundation
import WebKit
import UIKit
import CryptoKit
import WMFData

/// Website cookies are the sole authentication authority. Passwords, QQ codes
/// and privacy consent remain inside the site's own WebKit forms.
@MainActor final class TianyiSession: NSObject, ObservableObject, WKHTTPCookieStoreObserver {
    static let shared = TianyiSession()
    struct User: Equatable {
        let id: Int
        let name: String
        var avatarURL: URL?
        var avatar: UIImage?
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id && lhs.name == rhs.name && lhs.avatarURL == rhs.avatarURL && lhs.avatar === rhs.avatar
        }
    }
    @Published private(set) var users: [WMFTianyiSite: User] = [:]
    @Published private(set) var revision = 0
    @Published private(set) var errors: [WMFTianyiSite: String] = [:]
    private let store = WKWebsiteDataStore.default().httpCookieStore
    private var observedSites: Set<WMFTianyiSite> = [.zh]
    private var pending: Task<Void, Never>?
    private var queued: Set<WMFTianyiSite> = []
    private var anonymousSites: Set<WMFTianyiSite> = []
    private var hasIdentityCookies = false
    private var refreshing: Set<WMFTianyiSite> = []
    private var cookieIdentity = ""
    private struct CacheOwner: Codable { let fingerprint: String; let userID: Int }
    private var cacheOwners: [String: CacheOwner] = [:]
    private let network = URLSession(configuration: .ephemeral, delegate: TianyiAccountRedirectPolicy(), delegateQueue: nil)

    override init() {
        super.init()
        if let data = UserDefaults.standard.data(forKey: "tianyiCacheOwners"), let saved = try? JSONDecoder().decode([String: CacheOwner].self, from: data) { cacheOwners = saved }
        store.add(self)
    }
    func isAnonymousVerified(_ site: WMFTianyiSite) -> Bool { anonymousSites.contains(site) }
    func cacheIdentity(_ site: WMFTianyiSite) -> String {
        if anonymousSites.contains(site) { return "anonymous" }
        let remembered = cacheOwners[site.rawValue]
        let verifiedID = hasIdentityCookies && remembered?.fingerprint == cookieIdentity ? remembered?.userID : nil
        return WMFTianyiAccountMetadata.cacheScope(site: site, userID: users[site]?.id ?? verifiedID,
            credentialFingerprint: hasIdentityCookies ? cookieIdentity : nil)
    }
    private func persistCacheOwners() {
        if let data = try? JSONEncoder().encode(cacheOwners) { UserDefaults.standard.set(data, forKey: "tianyiCacheOwners") }
    }
    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        pending?.cancel()
        pending = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled, let self else { return }
            await self.synchronizeCookies()
            for site in self.observedSites { await self.refresh(site) }
        }
    }
    private static func isWikiCookie(_ cookie: HTTPCookie) -> Bool {
        WMFTianyiAccountMetadata.isWikiCookieDomain(cookie.domain)
    }
    func synchronizeCookies() async {
        let cookies = await store.allCookies().filter(Self.isWikiCookie)
        let key: (HTTPCookie) -> String = { "\($0.domain)|\($0.path)|\($0.name)" }
        let existing = Set(cookies.map(key))
        for cookie in HTTPCookieStorage.shared.cookies ?? [] where Self.isWikiCookie(cookie) && !existing.contains(key(cookie)) {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
        for cookie in cookies { HTTPCookieStorage.shared.setCookie(cookie) }
        let identityCookies = cookies.filter {
            let name = $0.name.lowercased()
            return ["session", "userid", "username", "token"].contains { name.hasSuffix($0) }
        }
        hasIdentityCookies = !identityCookies.isEmpty
        let identityText = identityCookies.map { key($0) + "=" + $0.value }.sorted().joined(separator: "\n")
        let digest = SHA256.hash(data: Data(identityText.utf8)).map { String(format: "%02x", $0) }.joined()
        if cookieIdentity != digest {
            cookieIdentity = digest
            users.removeAll(); anonymousSites.removeAll()
            revision += 1
        }
    }
    func refresh(_ site: WMFTianyiSite) async {
        observedSites.insert(site)
        guard !refreshing.contains(site) else { queued.insert(site); return }
        refreshing.insert(site)
        defer {
            refreshing.remove(site)
            if queued.remove(site) != nil { Task { await self.refresh(site) } }
        }
        await synchronizeCookies()
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-TianyiOffline") { return }
        #endif
        let generation = cookieIdentity
        do {
            struct Reply: Decodable {
                struct Query: Decodable {
                    struct Info: Decodable { let id: Int; let name: String }
                    let userinfo: Info
                }
                let query: Query
            }
            let data = try await fetch(site.apiURL(["action": "query", "meta": "userinfo"]), site: site)
            let info = try JSONDecoder().decode(Reply.self, from: data).query.userinfo
            guard generation == cookieIdentity, !Task.isCancelled else { return }
            errors[site] = nil
            guard info.id > 0 else {
                let priorScope = cacheIdentity(site)
                users.removeValue(forKey: site); anonymousSites.insert(site)
                cacheOwners[site.rawValue] = nil; persistCacheOwners()
                if priorScope != cacheIdentity(site) { revision += 1 }
                return
            }
            let prior = users[site]
            cacheOwners[site.rawValue] = CacheOwner(fingerprint: cookieIdentity, userID: info.id)
            persistCacheOwners()
            var user = User(id: info.id, name: info.name)
            users[site] = prior?.id == user.id ? prior : user
            if prior?.id != user.id { revision += 1 }
            if let html = try? await fetch(site.pageURL("Special:UserLogin"), site: site),
               let text = String(data: html, encoding: .utf8),
               let url = WMFTianyiAccountMetadata.avatarURL(in: text, site: site) {
                user.avatarURL = url
                if prior?.avatarURL == url { user.avatar = prior?.avatar }
                if user.avatar == nil, let imageData = try? await fetch(url, site: site) { user.avatar = UIImage(data: imageData) }
            }
            guard generation == cookieIdentity, !Task.isCancelled else { return }
            users[site] = user
        } catch {
            if !Task.isCancelled { errors[site] = t("无法读取账号状态，请重试。") }
        }
    }
    private func fetch(_ url: URL, site: WMFTianyiSite) async throws -> Data {
        guard WMFTianyiSite.matching(url) == site else { throw URLError(.badURL) }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 25)
        request.setValue("TianyiWiki-iOS/0.3", forHTTPHeaderField: "User-Agent")
        // Copy only cookies matching this exact URL; never print or persist their values ourselves.
        let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
        for (key, value) in HTTPCookie.requestHeaderFields(with: cookies) { request.setValue(value, forHTTPHeaderField: key) }
        request.httpShouldHandleCookies = false
        let (data, response) = try await network.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let finalURL = response.url, WMFTianyiSite.matching(finalURL) == site else { throw URLError(.badServerResponse) }
        return data
    }
}

/// Account requests never forward explicit cookie headers across a site boundary.
private final class TianyiAccountRedirectPolicy: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
        guard let original = task.originalRequest?.url, let site = WMFTianyiSite.matching(original),
              let url = request.url, WMFTianyiSite.matching(url) == site else { return nil }
        var next = request
        next.setValue(nil, forHTTPHeaderField: "Cookie")
        for (key, value) in HTTPCookie.requestHeaderFields(with: HTTPCookieStorage.shared.cookies(for: url) ?? []) { next.setValue(value, forHTTPHeaderField: key) }
        return next
    }
}

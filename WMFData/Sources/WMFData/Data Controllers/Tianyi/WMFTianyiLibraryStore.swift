import Foundation
import CryptoKit

public struct WMFTianyiLibraryStore: Sendable {
    private let store: any WMFKeyValueStore
    public init(store: (any WMFKeyValueStore)? = nil) { self.store = store ?? WMFUserDefaultsStore() }
    public func load(_ key: String) -> [WMFTianyiPage] { (try? store.load(key: "tianyi", key)) ?? [] }
    public func save(_ pages: [WMFTianyiPage], key: String) throws { try store.save(key: "tianyi", key, value: pages) }
}

/// Only explicitly bookmarked, anonymously fetched article HTML is persisted.
/// Images and other linked media remain online resources.
public actor WMFTianyiArticleCache {
    private let directory: URL
    public init(directory: URL) { self.directory = directory }
    private func file(for page: WMFTianyiPage) -> URL {
        let hash = SHA256.hash(data: Data(page.id.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(hash).appendingPathExtension("json")
    }
    public func save(_ article: WMFTianyiArticle, for page: WMFTianyiPage) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var resource = directory
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try resource.setResourceValues(values)
        try JSONEncoder().encode(article).write(to: file(for: page), options: [.atomic, .completeFileProtectionUnlessOpen])
    }
    public func load(_ page: WMFTianyiPage) throws -> WMFTianyiArticle {
        try JSONDecoder().decode(WMFTianyiArticle.self, from: Data(contentsOf: file(for: page)))
    }
    public func remove(_ page: WMFTianyiPage) throws {
        let url = file(for: page)
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }
    public func clear() throws {
        if FileManager.default.fileExists(atPath: directory.path) { try FileManager.default.removeItem(at: directory) }
    }
}

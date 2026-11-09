import XCTest
@testable import WMFData

final class WMFTianyiAccountMetadataTests: XCTestCase {
    func testCookieDomainBoundary() {
        for value in [".tyzx.org", "zh-wiki.tyzx.org", ".EN-WIKI.TYZX.ORG", "wiki.tyzx.org"] {
            XCTAssertTrue(WMFTianyiAccountMetadata.isWikiCookieDomain(value))
        }
        for value in ["tyzx.org.attacker.invalid", "evil-tyzx.org", "unrelated.tyzx.org", "wikipedia.org", ""] {
            XCTAssertFalse(WMFTianyiAccountMetadata.isWikiCookieDomain(value))
        }
    }
    func testAvatarUsesServerConfigurationAndDecodesJSONEscapes() {
        let html = #"<script>mw.config.set({"wgTyzxAvatarUrl":"\/images\/avatars\/42.png?v=7"});</script>"#
        XCTAssertEqual(WMFTianyiAccountMetadata.avatarURL(in: html, site: .zh)?.absoluteString,
                       "https://zh-wiki.tyzx.org/images/avatars/42.png?v=7")
    }
    func testUntrustedOrDefaultAvatarsFallBackToSystemIcon() {
        for value in ["https://attacker.invalid/photo.png", "http://zh-wiki.tyzx.org/photo.png",
                      "https://en-wiki.tyzx.org/photo.png", "https://user:password@zh-wiki.tyzx.org/photo.png",
                      "/extensions/TyzxAvatar/resources/default-avatar.svg"] {
            let literal = String(data: try! JSONEncoder().encode(value), encoding: .utf8)!
            XCTAssertNil(WMFTianyiAccountMetadata.avatarURL(in: "{\"wgTyzxAvatarUrl\":\(literal)}", site: .zh))
        }
        XCTAssertNil(WMFTianyiAccountMetadata.avatarURL(in: "not a page configuration", site: .zh))
    }
    func testAccountAndUnverifiedSessionCachesAreSeparateFromAnonymousCache() {
        let anon = WMFTianyiAccountMetadata.cacheScope(site: .zh, userID: nil, credentialFingerprint: nil)
        let first = WMFTianyiAccountMetadata.cacheScope(site: .zh, userID: 1, credentialFingerprint: nil)
        let second = WMFTianyiAccountMetadata.cacheScope(site: .zh, userID: 2, credentialFingerprint: nil)
        let pending = WMFTianyiAccountMetadata.cacheScope(site: .zh, userID: nil, credentialFingerprint: String(repeating: "a", count: 64))
        XCTAssertEqual(Set([anon, first, second, pending]).count, 4)
        XCTAssertNotEqual(first, WMFTianyiAccountMetadata.cacheScope(site: .fr, userID: 1, credentialFingerprint: nil))
        XCTAssertFalse(WMFTianyiAccountMetadata.cacheScope(site: .zh, userID: nil, credentialFingerprint: "../../not-a-token").contains("/"))
    }
}

import XCTest
@testable import WMFData

final class WMFTianyiDataControllerTests: XCTestCase {
    func testTitleEncodingAndSixHostWhitelist() throws {
        for site in WMFTianyiSite.allCases {
            let title = "中文 A&B?# /100%"
            let url = site.pageURL(title)
            XCTAssertEqual(site.title(in: url), title)
            XCTAssertEqual(WMFTianyiSite.matching(url), site)
            XCTAssertNil(url.fragment)
        }
        XCTAssertNil(WMFTianyiSite.matching(URL(string: "https://zh-wiki.tyzx.org.evil.example")!))
        XCTAssertNil(WMFTianyiSite.matching(URL(string: "http://zh-wiki.tyzx.org")!))
        XCTAssertNil(WMFTianyiSite.matching(URL(string: "https://user@zh-wiki.tyzx.org")!))
        XCTAssertNil(WMFTianyiSite.matching(URL(string: "https://zh-wiki.tyzx.org:8080")!))
        let percent = URL(string: "https://zh-wiki.tyzx.org/wiki/100%25")!
        XCTAssertEqual(WMFTianyiSite.zh.title(in: percent), "100%")
    }
    func testSearchAndParseUseUpstreamNetworkService() async throws {
        let controller = WMFTianyiDataController(service: WMFBasicService(urlSession: TianyiFixtureSession()))
        let result = try await controller.search("樱花", site: .zh)
        XCTAssertEqual(result.first?.title, "樱花节")
        let article = try await controller.article(WMFTianyiPage(title: "樱花节", site: .zh))
        XCTAssertEqual(article.revid, 42)
        XCTAssertEqual(article.sections.first?.anchor, "校园")
    }
    func testHTTPAPIErrorsAndHTMLChallengeAreNotEmptySuccesses() async {
        let controller = WMFTianyiDataController(service: WMFBasicService(urlSession: TianyiFixtureSession()))
        for term in ["http-error", "api-error", "challenge", "missing-query"] {
            do { _ = try await controller.search(term, site: .zh); XCTFail("Expected failure: \(term)") }
            catch { XCTAssertFalse(error.localizedDescription.isEmpty) }
        }
    }
    func testCancelledTaskDoesNotStartQuery() async {
        let controller = WMFTianyiDataController(service: WMFBasicService(urlSession: TianyiFixtureSession()))
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await controller.search("樱花", site: .zh)
        }
        task.cancel()
        do { _ = try await task.value; XCTFail("Expected cancellation") } catch { XCTAssertTrue(error is CancellationError) }
    }
    func testOfflineArticleRoundTripAndDeletion() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let cache = WMFTianyiArticleCache(directory: dir)
        let page = WMFTianyiPage(title: "../../中文 %?#", site: .zh)
        let article = WMFTianyiArticle(title: page.title, pageid: 1, revid: 42, text: "<p>校园记忆</p>", sections: [])
        try await cache.save(article, for: page)
        let restored = try await cache.load(page)
        XCTAssertEqual(restored.text, article.text)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil).count, 1)
        let otherLanguage = WMFTianyiPage(title: page.title, site: .en)
        do { _ = try await cache.load(otherLanguage); XCTFail("Languages must not share cache entries") } catch { }
        try await cache.remove(page)
        do { _ = try await cache.load(page); XCTFail("Deleted content must not be readable") } catch { }
    }
    func testMissingInterlanguagePageHasADistinctError() async {
        let controller = WMFTianyiDataController(service: WMFBasicService(urlSession: TianyiFixtureSession()))
        do {
            _ = try await controller.search("missing-page", site: .fr)
            XCTFail("Expected a missing-page error")
        } catch WMFTianyiError.missingPage { }
        catch { XCTFail("Unexpected error: \(error)") }
    }
    func testInterlanguageLinksRejectForeignHosts() throws {
        var article = WMFTianyiArticle(title: "学校", pageid: 1, revid: 42, text: "<p>学校</p>", sections: [])
        article.langlinks = [
            .init(lang: "en", title: "School", url: URL(string: "https://en-wiki.tyzx.org/wiki/School")!),
            .init(lang: "fr", title: "École", url: URL(string: "https://evil.example/wiki/Ecole")!),
            .init(lang: "de", title: "Schule", url: URL(string: "https://de.wikipedia.org/wiki/Schule")!)
        ]
        XCTAssertEqual(article.translatedPages.map(\.title), ["School"])
        XCTAssertEqual(article.translatedPages.first?.site, .en)
    }
    func testLibraryUsesUpstreamCodableStore() throws {
        let suite = "TianyiTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WMFTianyiLibraryStore(store: WMFUserDefaultsStore(defaults: defaults))
        let pages = [WMFTianyiPage(title: "学校历史", site: .zh)]
        try store.save(pages, key: "saved")
        XCTAssertEqual(store.load("saved"), pages)
        XCTAssertEqual(store.load("history"), [])
    }
}
private struct TianyiFixtureSession: WMFURLSession {
    func clearCachedData() { }
    func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFURLSessionDataTask {
        let parts = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        let term = parts.queryItems?.first { $0.name == "srsearch" }?.value
        let action = parts.queryItems?.first { $0.name == "action" }?.value
        let status = term == "http-error" ? 503 : 200
        let body: String
        if action == "parse" {
            body = #"{"parse":{"title":"樱花节","pageid":1,"revid":42,"text":"<p>校园记忆</p>","sections":[{"index":"1","line":"校园","anchor":"校园"}]}}"#
        } else {
            switch term {
            case "api-error": body = #"{"error":{"code":"readapidenied","info":"Access denied"}}"#
            case "challenge": body = "<html>Cloud challenge</html>"
            case "missing-query": body = "{}"
            case "missing-page": body = #"{"error":{"code":"missingtitle","info":"The page does not exist"}}"#
            default: body = #"{"query":{"search":[{"pageid":1,"title":"樱花节","snippet":"校园"}]}}"#
            }
        }
        return TianyiFixtureTask {
            completionHandler(Data(body.utf8), HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil), nil)
        }
    }
}
private struct TianyiFixtureTask: WMFURLSessionDataTask {
    let run: @Sendable () -> Void
    func resume() { run() }
}

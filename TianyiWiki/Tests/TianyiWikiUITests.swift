import XCTest
import UIKit

final class TianyiWikiUITests: XCTestCase {
    @MainActor func testReadingSearchAndSavedLibrary() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN", "-tianyiInterface", "zh", "-tianyiSite", "zh", "-tianyiSelectedTab", "0", "-readerZoom", "1.0"]
        app.launch()
        continueAfterFailure = false
        XCTAssertTrue(app.buttons["开始阅读"].waitForExistence(timeout: 10))
        attach(app, "01-探索")
        app.buttons["开始阅读"].tap()
        XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 20))
        // Confirm that actual article content rendered, rather than just creating a web view.
        XCTAssertTrue(app.webViews.staticTexts["江苏省天一中学"].firstMatch.waitForExistence(timeout: 30))
        attach(app, "02-阅读")
        if app.buttons["收藏词条"].exists { app.buttons["收藏词条"].tap() }
        XCTAssertTrue(app.buttons["取消收藏"].exists)
        app.navigationBars.buttons.firstMatch.tap()
        tab(app, "书架").tap()
        XCTAssertTrue(app.staticTexts["江苏省天一中学"].firstMatch.waitForExistence(timeout: 5))
        attach(app, "03-书架")
        tab(app, "搜索").tap()
        let search = app.textFields["tianyi-search"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("樱花")
        XCTAssertTrue(app.staticTexts["樱花节"].firstMatch.waitForExistence(timeout: 30))
        attach(app, "04-搜索")
        app.terminate()
        app.launch()
        tab(app, "书架").tap()
        XCTAssertTrue(app.staticTexts["江苏省天一中学"].firstMatch.waitForExistence(timeout: 5))
        app.staticTexts["江苏省天一中学"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["正在阅读已保存正文 · 图片与媒体需联网"].waitForExistence(timeout: 10))
        attach(app, "05-离线正文")
        app.navigationBars.buttons.firstMatch.tap()
        tab(app, "设置").tap()
        XCTAssertTrue(app.staticTexts["维基语言"].exists)
        attach(app, "06-设置")
    }
    @MainActor func testSixLanguageInterfaces() throws {
        continueAfterFailure = false
        let cases = [("zh", "探索", "开始阅读"), ("en", "Explore", "Start reading"), ("fr", "Explorer", "Commencer la lecture"), ("ja", "探索", "読み始める"), ("ko", "둘러보기", "읽기 시작"), ("lzh", "覽", "始讀")]
        let app = XCUIApplication()
        for (code, tab, start) in cases {
            app.launchArguments = ["-tianyiSelectedTab", "0", "-tianyiInterface", code, "-tianyiSite", "zh"]
            app.launch()
            XCTAssertTrue(self.tab(app, tab).waitForExistence(timeout: 10), code)
            XCTAssertTrue(app.buttons[start].exists, code)
            attach(app, "language-\(code)")
            app.terminate()
        }
    }
    @MainActor func testEnglishUIWithChineseAndEnglishArticles() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-tianyiSelectedTab", "0", "-tianyiInterface", "en", "-tianyiSite", "zh"]
        app.launch()
        XCTAssertTrue(app.buttons["Start reading"].waitForExistence(timeout: 10))
        app.buttons["Start reading"].tap()
        XCTAssertTrue(app.navigationBars["江苏省天一中学"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 30))
        // Explicit refresh also refreshes older cached articles without langlinks.
        app.buttons["More"].tap()
        app.buttons["Refresh article"].tap()
        app.buttons["Article languages"].tap()
        let linked = app.staticTexts["Jiangsu Tianyi High School"].firstMatch
        XCTAssertTrue(linked.waitForExistence(timeout: 30))
        linked.tap()
        XCTAssertTrue(app.navigationBars["Jiangsu Tianyi High School"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 30))
        attach(app, "cross-language-en")
    }
    @MainActor func testChangeInterfaceLanguageInSettings() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN", "-tianyiSelectedTab", "3"]
        app.launch()
        XCTAssertTrue(app.buttons["interface-language"].waitForExistence(timeout: 10))
        app.buttons["interface-language"].tap()
        app.buttons["中文"].tap()
        XCTAssertTrue(tab(app, "设置").waitForExistence(timeout: 5))
        app.buttons["interface-language"].tap()
        app.buttons["English"].tap()
        XCTAssertTrue(tab(app, "Settings").waitForExistence(timeout: 5))
        XCTAssertTrue(tab(app, "Explore").exists)
        app.buttons["interface-language"].tap()
        app.buttons["Français"].tap()
        XCTAssertTrue(tab(app, "Réglages").waitForExistence(timeout: 5))
        app.buttons["interface-language"].tap()
        app.buttons["中文"].tap()
        XCTAssertTrue(tab(app, "设置").waitForExistence(timeout: 5))
    }
    @MainActor func testBadAppleEasterEggPlaysPausesAndRestoresArticle() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-tianyiSelectedTab", "0", "-tianyiInterface", "zh", "-tianyiSite", "zh", "-AppleLanguages", "(zh-Hans)"]
        app.launch()
        tab(app, "搜索").tap()
        let search = app.textFields["tianyi-search"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap(); search.typeText("Bad Apple!!")
        let result = app.staticTexts["Bad Apple!!"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 30)); result.tap()
        let web = app.webViews.firstMatch
        XCTAssertTrue(web.waitForExistence(timeout: 30))
        let play = app.buttons["播放"]
        XCTAssertTrue(play.waitForExistence(timeout: 45))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: play)
        waitForExpectations(timeout: 45)
        play.tap()
        XCTAssertTrue(app.buttons["暂停"].waitForExistence(timeout: 15))
        let progress = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "0:[0-9]{2} / 3:39")).firstMatch
        XCTAssertTrue(progress.waitForExistence(timeout: 10))
        let advances = NSPredicate { _, _ in progress.exists && progress.label != "0:00 / 3:39" }
        expectation(for: advances, evaluatedWith: nil)
        waitForExpectations(timeout: 15)
        attach(app, "BadApple-playing")
        app.buttons["暂停"].tap()
        XCTAssertTrue(app.buttons["播放"].exists)
        app.buttons["阅读词条"].tap()
        XCTAssertTrue(app.buttons["播放"].exists)
        XCTAssertEqual(progress.label, "0:00 / 3:39")
        app.buttons["更多"].tap()
        app.buttons["评论与讨论"].tap()
        XCTAssertTrue(app.buttons["完成"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["此词条关闭了评论功能"].waitForExistence(timeout: 30))
        app.buttons["完成"].tap()
        attach(app, "BadApple-restored")
    }
    @MainActor func testHomeAndBadAppleUseOfflineCache() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        let arguments = ["-tianyiSelectedTab", "0", "-tianyiInterface", "zh", "-tianyiSite", "zh"]
        app.launchArguments = arguments
        app.launch()
        tab(app, "搜索").tap()
        let field = app.textFields["tianyi-search"]
        field.tap(); field.typeText("Bad Apple!!")
        let result = app.staticTexts["Bad Apple!!"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 30)); result.tap()
        let play = app.buttons["播放"]
        XCTAssertTrue(play.waitForExistence(timeout: 20))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: play)
        waitForExpectations(timeout: 45)
        app.terminate()
        app.launchArguments = arguments + ["-TianyiOffline"]
        app.launch()
        XCTAssertTrue(app.staticTexts["欢迎来到天一维基"].waitForExistence(timeout: 10))
        attach(app, "native-home-offline")
        tab(app, "书架").tap()
        app.buttons["阅读历史"].tap()
        app.staticTexts["Bad Apple!!"].firstMatch.tap()
        XCTAssertTrue(app.buttons["播放"].waitForExistence(timeout: 10))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.buttons["播放"])
        waitForExpectations(timeout: 10)
        XCTAssertTrue(app.staticTexts["已缓存正文、音乐与动画，可离线播放"].waitForExistence(timeout: 10))
        app.buttons["播放"].tap()
        XCTAssertTrue(app.buttons["暂停"].waitForExistence(timeout: 5))
        let progress = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "0:[0-9]{2} / 3:39")).firstMatch
        expectation(for: NSPredicate { _, _ in progress.exists && progress.label != "0:00 / 3:39" }, evaluatedWith: nil)
        waitForExpectations(timeout: 10)
        attach(app, "native-BadApple-offline")
    }
    @MainActor func testUpstreamArticleToolbarAndFind() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-tianyiSelectedTab", "0", "-tianyiInterface", "zh", "-tianyiSite", "zh", "-readerZoom", "1.0", "-AppleLanguages", "(zh-Hans)"]
        app.launch()
        XCTAssertTrue(app.buttons["开始阅读"].waitForExistence(timeout: 10))
        app.buttons["开始阅读"].tap()
        XCTAssertTrue(app.webViews.staticTexts["江苏省天一中学"].firstMatch.waitForExistence(timeout: 30))
        let bar = app.toolbars.firstMatch
        XCTAssertTrue(bar.waitForExistence(timeout: 5), "Reader must use the navigation controller's native UIToolbar")
        for label in ["词条目录", "词条语言", "词条内查找", "阅读选项", "更多"] {
            XCTAssertTrue(app.buttons[label].exists, label)
        }
        attach(app, "upstream-article-toolbar")
        app.buttons["词条内查找"].tap()
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap(); field.typeText("历史")
        attach(app, "upstream-article-find")
    }
    @MainActor func testEnabledCommentsRegionIsVisible() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-tianyiSelectedTab", "0", "-tianyiInterface", "zh", "-tianyiSite", "zh", "-readerZoom", "1.0"]
        app.launch()
        XCTAssertTrue(app.buttons["开始阅读"].waitForExistence(timeout: 10))
        app.buttons["开始阅读"].tap()
        XCTAssertTrue(app.buttons["更多"].waitForExistence(timeout: 10))
        app.buttons["更多"].tap()
        app.buttons["评论与讨论"].tap()
        let heading = app.webViews.staticTexts["访客评论"].firstMatch
        XCTAssertTrue(heading.waitForExistence(timeout: 30))
        XCTAssertTrue(app.descendants(matching: .any)["comments-loading"].waitForNonExistence(timeout: 15))
        // WebKit on iPadOS 27 can expose a text node before it has a finite activation point.
        // Verify its visible bounds instead of asking a read-only heading for a tap target.
        let web = app.webViews.firstMatch
        expectation(for: NSPredicate { _, _ in
            let rect = heading.frame
            return rect.width > 0 && rect.height > 0 && rect.minX.isFinite && rect.minY.isFinite && web.frame.contains(rect)
        }, evaluatedWith: nil)
        waitForExpectations(timeout: 15)
        XCTAssertFalse(app.staticTexts["此词条关闭了评论功能"].exists)
        attach(app, "comments-enabled")
        // Read-only validation: never submit a comment to the production wiki.
        app.buttons["完成"].tap()
    }
    @MainActor func testIPadRotationAndReaderPresentations() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else { throw XCTSkip("iPad layout test") }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-tianyiSelectedTab", "0", "-tianyiInterface", "zh", "-tianyiSite", "zh", "-readerZoom", "1.6"]
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()
        XCTAssertTrue(app.buttons["开始阅读"].waitForExistence(timeout: 10))
        attach(app, "iPad-home-portrait")
        XCUIDevice.shared.orientation = .landscapeLeft
        expectation(for: NSPredicate { _, _ in app.frame.width > app.frame.height }, evaluatedWith: nil)
        waitForExpectations(timeout: 10)
        XCTAssertTrue(app.buttons["开始阅读"].isHittable)
        attach(app, "iPad-home-landscape")
        app.buttons["开始阅读"].tap()
        XCTAssertTrue(app.webViews.staticTexts["江苏省天一中学"].firstMatch.waitForExistence(timeout: 30))
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "iPad-reader-hierarchy"; tree.lifetime = .keepAlways; add(tree)
        attach(app, "iPad-reader-landscape")
        XCTAssertTrue(app.navigationBars.buttons.firstMatch.exists, "Reader must retain a visible back button")
        for label in ["词条目录", "词条语言", "阅读选项", "词条内查找", "更多"] {
            XCTAssertTrue(app.buttons[label].isHittable, label)
        }
        app.buttons["词条目录"].tap()
        XCTAssertTrue(app.buttons["完成"].waitForExistence(timeout: 5))
        attach(app, "iPad-contents-sheet")
        app.buttons["完成"].tap()
        app.buttons["词条语言"].tap()
        XCTAssertTrue(app.staticTexts["浏览其他语言站"].waitForExistence(timeout: 5))
        app.buttons["完成"].tap()
        app.buttons["阅读选项"].tap()
        XCTAssertTrue(app.buttons["放大字号"].waitForExistence(timeout: 5))
        app.buttons["放大字号"].tap()
        app.buttons["更多"].tap()
        app.buttons["分享词条"].tap()
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 5))
        attach(app, "iPad-share-popover")
        // Dismiss the share popover by tapping outside its anchored presentation.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.15)).tap()
        XCUIDevice.shared.orientation = .portrait
        expectation(for: NSPredicate { _, _ in app.frame.height > app.frame.width }, evaluatedWith: nil)
        waitForExpectations(timeout: 10)
        attach(app, "iPad-reader-portrait")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["开始阅读"].waitForExistence(timeout: 5))
        XCTAssertTrue(tab(app, "搜索").isHittable, "Returning home must restore the iPad tabs")
    }
    @MainActor func testAccountWebsiteLoginAndRegistration() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-tianyiSelectedTab", "0", "-tianyiInterface", "zh", "-tianyiSite", "zh", "-AppleLanguages", "(zh-Hans)"]
        app.launch()
        XCTAssertTrue(app.buttons["account-button"].waitForExistence(timeout: 10))
        app.buttons["account-button"].tap()
        XCTAssertTrue(app.buttons["account-login"].waitForExistence(timeout: 10))
        app.buttons["account-login"].tap()
        XCTAssertTrue(app.webViews.secureTextFields.firstMatch.waitForExistence(timeout: 30))
        XCTAssertTrue(app.webViews.textFields.firstMatch.exists)
        attach(app, "website-login")
        app.buttons["web-flow-done-login"].tap()
        XCTAssertTrue(app.webViews.secureTextFields.firstMatch.waitForNonExistence(timeout: 10))
        app.buttons["account-register"].tap()
        XCTAssertTrue(app.webViews.staticTexts["注册前请阅读隐私政策"].firstMatch.waitForExistence(timeout: 30))
        XCTAssertTrue(app.webViews.staticTexts["我已阅读并理解隐私政策"].firstMatch.exists)
        attach(app, "website-registration-privacy")
        let policy = app.webViews.links["打开并阅读隐私政策"].firstMatch
        XCTAssertTrue(policy.exists); policy.tap()
        XCTAssertTrue(app.webViews.staticTexts["隐私政策"].firstMatch.waitForExistence(timeout: 30))
        app.buttons["web-flow-done-page"].tap()
        XCTAssertTrue(app.webViews.staticTexts["注册前请阅读隐私政策"].firstMatch.waitForExistence(timeout: 10))
        // Consent, real credentials and QQ verification are completed by the account owner.
    }
    @MainActor func testArticleTabsSwitchPersistAndClose() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        let arguments = ["-tianyiSelectedTab", "0", "-tianyiInterface", "zh", "-tianyiSite", "zh"]
        app.launchArguments = arguments + ["-TianyiResetTabs"]
        app.launch()
        app.buttons["开始阅读"].tap()
        XCTAssertTrue(app.navigationBars["江苏省天一中学"].waitForExistence(timeout: 10))
        app.buttons["article-tabs-button"].tap()
        app.buttons["新建标签页"].tap()
        let search = app.textFields["tianyi-search"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap(); search.typeText("Bad Apple!!")
        let result = app.staticTexts["Bad Apple!!"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 30)); result.tap()
        app.buttons["article-tabs-button"].tap()
        let cards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'article-tab-'"))
        XCTAssertEqual(cards.count, 2)
        attach(app, "article-tabs")
        cards.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["江苏省天一中学"].waitForExistence(timeout: 10))
        app.launchArguments = arguments
        app.terminate(); app.launch()
        app.buttons["article-tabs-button"].tap()
        XCTAssertEqual(cards.count, 2)
        cards.element(boundBy: 1).tap()
        XCTAssertTrue(app.navigationBars["Bad Apple!!"].waitForExistence(timeout: 10))
        app.buttons["article-tabs-button"].tap()
        app.buttons["关闭标签页 江苏省天一中学"].tap()
        XCTAssertEqual(cards.count, 1)
        app.buttons["关闭标签页 Bad Apple!!"].tap()
        XCTAssertTrue(app.staticTexts["暂无标签页"].waitForExistence(timeout: 5))
    }
    @MainActor func testInlineCommentsOpenLivePanel() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-tianyiSelectedTab", "0", "-tianyiInterface", "zh", "-tianyiSite", "zh"]
        app.launch(); app.buttons["开始阅读"].tap()
        let entry = app.webViews.buttons["查看评论"].firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 30))
        XCTAssertFalse(app.webViews.staticTexts["Loading comments..."].exists)
        entry.tap()
        XCTAssertTrue(app.buttons["登录"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.webViews.staticTexts["您未被允许发表评论。"].firstMatch.waitForExistence(timeout: 30))
        XCTAssertFalse(app.webViews.staticTexts["Loading comments..."].exists)
        attach(app, "live-comments-from-article")
    }
    @MainActor private func tab(_ app: XCUIApplication, _ title: String) -> XCUIElement {
        let bottom = app.tabBars.buttons[title]
        if bottom.exists { return bottom }
        // iPadOS 18+ exposes the floating top tabs as cells rather than a TabBar.
        let cell = app.cells.matching(identifier: title).firstMatch
        if cell.exists { return cell }
        return app.buttons[title].firstMatch
    }
    @MainActor private func attach(_ app: XCUIApplication, _ name: String) {
        // Accessibility geometry can update before the compositor commits rotation or sheets.
        Thread.sleep(forTimeInterval: 0.5)
        let item = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        item.name = name; item.lifetime = .keepAlways
        add(item)
    }
}

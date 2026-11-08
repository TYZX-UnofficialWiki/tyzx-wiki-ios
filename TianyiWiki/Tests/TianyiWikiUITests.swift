import XCTest

final class TianyiWikiUITests: XCTestCase {
    @MainActor func testReadingSearchAndSavedLibrary() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN", "-tianyiInterface", "zh", "-tianyiSite", "zh", "-tianyiSelectedTab", "0"]
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
        app.tabBars.buttons["书架"].tap()
        XCTAssertTrue(app.staticTexts["江苏省天一中学"].firstMatch.waitForExistence(timeout: 5))
        attach(app, "03-书架")
        app.tabBars.buttons["搜索"].tap()
        let search = app.textFields["tianyi-search"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("樱花")
        XCTAssertTrue(app.staticTexts["樱花节"].firstMatch.waitForExistence(timeout: 30))
        attach(app, "04-搜索")
        app.terminate()
        app.launch()
        app.tabBars.buttons["书架"].tap()
        XCTAssertTrue(app.staticTexts["江苏省天一中学"].firstMatch.waitForExistence(timeout: 5))
        app.staticTexts["江苏省天一中学"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["正在阅读已保存正文 · 图片与媒体需联网"].waitForExistence(timeout: 10))
        attach(app, "05-离线正文")
        app.navigationBars.buttons.firstMatch.tap()
        app.tabBars.buttons["设置"].tap()
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
            XCTAssertTrue(app.tabBars.buttons[tab].waitForExistence(timeout: 10), code)
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
        app.buttons["Reading options"].tap()
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
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launch()
        let settings = app.tabBars.buttons.element(boundBy: 3)
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        settings.tap()
        app.buttons["interface-language"].tap()
        app.buttons["中文"].tap()
        XCTAssertTrue(app.tabBars.buttons["设置"].waitForExistence(timeout: 5))
        app.buttons["interface-language"].tap()
        app.buttons["English"].tap()
        XCTAssertTrue(app.tabBars.buttons["Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Explore"].exists)
        app.buttons["interface-language"].tap()
        app.buttons["Français"].tap()
        XCTAssertTrue(app.tabBars.buttons["Réglages"].waitForExistence(timeout: 5))
        app.buttons["interface-language"].tap()
        app.buttons["中文"].tap()
        XCTAssertTrue(app.tabBars.buttons["设置"].waitForExistence(timeout: 5))
    }
    @MainActor func testBadAppleEasterEggPlaysPausesAndRestoresArticle() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-tianyiSelectedTab", "0", "-tianyiInterface", "zh", "-tianyiSite", "zh", "-AppleLanguages", "(zh-Hans)"]
        app.launch()
        app.tabBars.buttons["搜索"].tap()
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
        app.buttons["评论与讨论"].tap()
        XCTAssertTrue(app.buttons["完成"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["此词条关闭了评论功能"].waitForExistence(timeout: 15))
        app.buttons["完成"].tap()
        attach(app, "BadApple-restored")
    }
    @MainActor func testHomeAndBadAppleUseOfflineCache() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        let arguments = ["-tianyiSelectedTab", "0", "-tianyiInterface", "zh", "-tianyiSite", "zh"]
        app.launchArguments = arguments
        app.launch()
        app.tabBars.buttons["搜索"].tap()
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
        app.tabBars.buttons["书架"].tap()
        app.buttons["阅读历史"].tap()
        app.staticTexts["Bad Apple!!"].firstMatch.tap()
        XCTAssertTrue(app.buttons["播放"].waitForExistence(timeout: 10))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.buttons["播放"])
        waitForExpectations(timeout: 10)
        app.buttons["播放"].tap()
        XCTAssertTrue(app.buttons["暂停"].waitForExistence(timeout: 5))
        let progress = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "0:[0-9]{2} / 3:39")).firstMatch
        expectation(for: NSPredicate { _, _ in progress.exists && progress.label != "0:00 / 3:39" }, evaluatedWith: nil)
        waitForExpectations(timeout: 10)
        attach(app, "native-BadApple-offline")
    }
    @MainActor private func attach(_ app: XCUIApplication, _ name: String) {
        let item = XCTAttachment(screenshot: app.screenshot())
        item.name = name; item.lifetime = .keepAlways
        add(item)
    }
}

import SwiftUI
import WMFData
import WMFComponents

@MainActor final class TianyiLibrary: ObservableObject {
    @Published private(set) var saved: [WMFTianyiPage]
    @Published private(set) var history: [WMFTianyiPage]
    @Published var storageError: String?
    let cache: WMFTianyiArticleCache
    private let store = WMFTianyiLibraryStore()
    init() {
        saved = store.load("saved"); history = store.load("history")
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("TianyiArticles", isDirectory: true)
        cache = WMFTianyiArticleCache(directory: directory)
    }
    func contains(_ page: WMFTianyiPage) -> Bool { saved.contains { $0.id == page.id } }
    func toggle(_ page: WMFTianyiPage, article: WMFTianyiArticle?) async {
        do {
            if contains(page) {
                try await cache.remove(page)
                let updated = saved.filter { $0.id != page.id }
                try store.save(updated, key: "saved"); saved = updated
            } else if let article {
                try await cache.save(article, for: page)
                let updated = [page] + saved
                try store.save(updated, key: "saved"); saved = updated
            }
        } catch { storageError = error.localizedDescription }
    }
    func visit(_ page: WMFTianyiPage) {
        let updated = Array(([page] + history.filter { $0.id != page.id }).prefix(200))
        do { try store.save(updated, key: "history"); history = updated }
        catch { storageError = error.localizedDescription }
    }
    func clearHistory() {
        do { try store.save([WMFTianyiPage](), key: "history"); history = [] }
        catch { storageError = error.localizedDescription }
    }
    func clearOffline() async {
        do {
            try await cache.clear(); try await TianyiBadAppleCache.shared.clear(); try store.save([WMFTianyiPage](), key: "saved"); saved = []
        } catch { storageError = error.localizedDescription }
    }
}

@main struct TianyiApp: App {
    @AppStorage("tianyiInterface") private var interface = TianyiL10n.defaultLanguage
    var body: some Scene { WindowGroup { TianyiContainer(language: interface).id(interface).ignoresSafeArea() } }
}

/// Uses upstream UIKit coordinators, hosting and navigation controllers, rather
/// than nesting a second SwiftUI navigation stack inside the WMF navigation stack.
struct TianyiContainer: UIViewControllerRepresentable {
    let language: String
    func makeUIViewController(context: Context) -> UITabBarController { context.coordinator.start() }
    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {
        context.coordinator.updateTitles()
        let theme = context.environment.colorScheme == .dark ? WMFTheme.dark : WMFTheme.light
        if WMFAppEnvironment.current.theme != theme { WMFAppEnvironment.current.set(theme: theme) }
    }
    func makeCoordinator() -> TianyiCoordinator { TianyiCoordinator() }
}

@MainActor final class TianyiCoordinator: NSObject, UITabBarControllerDelegate, UINavigationControllerDelegate {
    let library = TianyiLibrary()
    private var navigationControllers: [WMFComponentNavigationController] = []
    private weak var tabController: UITabBarController?
    func start() -> UITabBarController {
        WMFDataEnvironment.current.userAgentUtility = { "TianyiWiki-iOS/0.2 (https://github.com/TYZX-UnofficialWiki/tyzx-wiki-ios)" }
        let tab = UITabBarController()
        let selectedIndex = min(3, max(0, UserDefaults.standard.integer(forKey: "tianyiSelectedTab")))
        tabController = tab
        let open: @MainActor @Sendable (WMFTianyiPage) -> Void = { [weak self, weak tab] page in
            guard let self, let nav = tab?.selectedViewController as? WMFComponentNavigationController else { return }
            self.show(page, in: nav)
        }
        let roots: [(String, String, AnyView)] = [
            (t("探索"), "globe.asia.australia", AnyView(TianyiExploreView(open: open))),
            (t("搜索"), "magnifyingglass", AnyView(TianyiSearchView(open: open))),
            (t("书架"), "books.vertical", AnyView(TianyiLibraryView(open: open))),
            (t("设置"), "gearshape", AnyView(TianyiSettingsView { [weak self] language in self?.updateTitles(language: language) }))
        ]
        navigationControllers = roots.map { title, symbol, view in
            let host = WMFComponentHostingController(rootView: view.environmentObject(library))
            host.navigationItem.title = title == t("探索") ? t("天一维基") : title
            let nav = WMFComponentNavigationController(rootViewController: host, modalPresentationStyle: .fullScreen)
            nav.delegate = self
            nav.navigationBar.prefersLargeTitles = true
            nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: symbol), selectedImage: nil)
            return nav
        }
        if #available(iOS 18.0, *) {
            tab.tabs = zip(navigationControllers, roots).enumerated().map { index, pair in
                let (nav, metadata) = pair
                return UITab(title: metadata.0, image: UIImage(systemName: metadata.1), identifier: "tianyi-tab-\(index)") { _ in nav }
            }
        } else {
            tab.viewControllers = navigationControllers
        }
        if #available(iOS 18.0, *) { tab.selectedTab = tab.tabs[selectedIndex] }
        else { tab.selectedIndex = selectedIndex }
        tab.delegate = self
        return tab
    }
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        updateIPadTabs(navigationController, showing: viewController)
    }
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // Also restores the correct state after an interactive back gesture is cancelled.
        updateIPadTabs(navigationController, showing: viewController)
    }
    private func updateIPadTabs(_ navigationController: UINavigationController, showing viewController: UIViewController) {
        if #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            tabController?.setTabBarHidden(viewController !== navigationController.viewControllers.first, animated: false)
        }
    }
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        UserDefaults.standard.set(tabBarController.selectedIndex, forKey: "tianyiSelectedTab")
    }
    @available(iOS 18.0, *)
    func tabBarController(_ tabBarController: UITabBarController, didSelectTab selectedTab: UITab, previousTab: UITab?) {
        if let index = tabBarController.tabs.firstIndex(where: { $0.identifier == selectedTab.identifier }) {
            UserDefaults.standard.set(index, forKey: "tianyiSelectedTab")
        }
    }
    func updateTitles(language: String? = nil) {
        func label(_ key: String) -> String { TianyiL10n.text(key, language: language) }
        let keys = ["探索", "搜索", "书架", "设置"]
        for (nav, key) in zip(navigationControllers, keys) {
            nav.viewControllers.first?.navigationItem.title = label(key == "探索" ? "天一维基" : key)
            nav.tabBarItem.title = label(key)
        }
        if #available(iOS 18.0, *), let tabController {
            for (tab, key) in zip(tabController.tabs, keys) { tab.title = label(key) }
        }
    }
    private func show(_ page: WMFTianyiPage, in nav: WMFComponentNavigationController) {
        // Special, help and category pages use the complete site so templates,
        // authentication and interactive flows retain their existing behavior.
        if ["Special:", "特殊:", "Category:", "分类:", "Talk:", "讨论:"].contains(where: { page.title.hasPrefix($0) }) {
            let host = WMFComponentHostingController(rootView: TianyiSiteView(url: page.url))
            host.title = page.title; host.hidesBottomBarWhenPushed = UIDevice.current.userInterfaceIdiom != .pad
            nav.pushViewController(host, animated: true)
            return
        }
        let reader = TianyiReaderView(page: page) { [weak self, weak nav] linked in
            guard let self, let nav else { return }; self.show(linked, in: nav)
        }.environmentObject(library)
        let host = WMFComponentHostingController(rootView: reader)
        host.title = page.title
        host.navigationItem.largeTitleDisplayMode = .never
        host.hidesBottomBarWhenPushed = UIDevice.current.userInterfaceIdiom != .pad
        nav.pushViewController(host, animated: true)
    }
}

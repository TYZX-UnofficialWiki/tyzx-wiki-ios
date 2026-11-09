import SwiftUI
import WMFData
import WMFComponents
import Combine

@MainActor final class TianyiLibrary: ObservableObject {
    @Published private(set) var saved: [WMFTianyiPage]
    @Published private(set) var history: [WMFTianyiPage]
    @Published var storageError: String?
    private let session: TianyiSession
    private let directory: URL
    private var caches: [String: WMFTianyiArticleCache] = [:]
    private let store = WMFTianyiLibraryStore()
    init(session: TianyiSession) {
        self.session = session
        saved = store.load("saved"); history = store.load("history")
        directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("TianyiArticles", isDirectory: true)
    }
    func prepareSession() async { await session.synchronizeCookies() }
    func cacheIdentity(for page: WMFTianyiPage) -> String { session.cacheIdentity(page.site) }
    func cache(for page: WMFTianyiPage) -> WMFTianyiArticleCache {
        let identity = session.cacheIdentity(page.site)
        if let cache = caches[identity] { return cache }
        let location = identity == "anonymous" ? directory : directory.appendingPathComponent("Accounts/" + identity, isDirectory: true)
        let cache = WMFTianyiArticleCache(directory: location)
        caches[identity] = cache
        return cache
    }
    func cachedArticle(for page: WMFTianyiPage) async -> WMFTianyiArticle? {
        if let article = try? await cache(for: page).load(page) { return article }
        // Anonymous copies were downloaded without account privileges and are safe
        // to keep available while an offline website session is being verified.
        if cacheIdentity(for: page) != "anonymous" { return try? await WMFTianyiArticleCache(directory: directory).load(page) }
        return nil
    }
    func contains(_ page: WMFTianyiPage) -> Bool { saved.contains { $0.id == page.id } }
    func toggle(_ page: WMFTianyiPage, article: WMFTianyiArticle?, expectedScope: String? = nil) async {
        await prepareSession()
        if let expectedScope, expectedScope != cacheIdentity(for: page) { return }
        do {
            if contains(page) {
                try await cache(for: page).remove(page)
                let updated = saved.filter { $0.id != page.id }
                try store.save(updated, key: "saved"); saved = updated
            } else if let article {
                try await cache(for: page).save(article, for: page)
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
            try await WMFTianyiArticleCache(directory: directory).clear(); caches.removeAll(); try await TianyiBadAppleCache.shared.clear(); try store.save([WMFTianyiPage](), key: "saved"); saved = []
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
    let session = TianyiSession.shared
    lazy var library = TianyiLibrary(session: session)
    let articleTabs = TianyiArticleTabs()
    private var pages: [ObjectIdentifier: WMFTianyiPage] = [:]
    private var articleTabIDs: [ObjectIdentifier: UUID] = [:]
    private var observations: Set<AnyCancellable> = []
    private var currentSite: WMFTianyiSite { WMFTianyiSite(rawValue: UserDefaults.standard.string(forKey: "tianyiSite") ?? "zh") ?? .zh }
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
            let host = TianyiHostingContainer(rootView: view.environmentObject(library).environmentObject(session))
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
        session.$users.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.refreshHeaders() }.store(in: &observations)
        articleTabs.$tabs.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.refreshHeaders() }.store(in: &observations)
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification).receive(on: DispatchQueue.main).sink { [weak self] _ in
            guard let self else { return }
            self.refreshHeaders()
        }.store(in: &observations)
        refreshHeaders()
        Task { await session.refresh(currentSite) }
        return tab
    }
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        configureHeader(viewController)
        updateIPadTabs(navigationController, showing: viewController)
        navigationController.setToolbarHidden(!(viewController is TianyiArticleToolbarHosting), animated: false)
    }
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if let id = articleTabIDs[ObjectIdentifier(viewController)] {
            let stack = Array(navigationController.viewControllers.dropFirst())
            articleTabs.selected = id
            articleTabs.update(id, pages: stack.compactMap { pages[ObjectIdentifier($0)] }, controllers: stack)
        }
        // Also restores the correct state after an interactive back gesture is cancelled.
        configureHeader(viewController)
        updateIPadTabs(navigationController, showing: viewController)
        navigationController.setToolbarHidden(!(viewController is TianyiArticleToolbarHosting), animated: false)
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
    private func refreshHeaders() {
        for nav in navigationControllers { for controller in nav.viewControllers { configureHeader(controller) } }
    }
    private func configureHeader(_ owner: UIViewController) {
        let site = pages[ObjectIdentifier(owner)]?.site ?? currentSite
        let account = UIButton(type: .system)
        if let avatar = session.users[site]?.avatar {
            account.setImage(avatar.withRenderingMode(.alwaysOriginal), for: .normal)
            account.imageView?.contentMode = .scaleAspectFill
            account.layer.cornerRadius = 14; account.clipsToBounds = true
        } else { account.setImage(UIImage(systemName: "person.crop.circle"), for: .normal) }
        account.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([account.widthAnchor.constraint(equalToConstant: 28), account.heightAnchor.constraint(equalToConstant: 28)])
        account.tintColor = .label
        account.accessibilityLabel = session.users[site]?.name ?? t("登录或注册")
        account.accessibilityIdentifier = "account-button"
        account.addAction(UIAction { [weak self] _ in self?.presentAccount(site) }, for: .touchUpInside)
        let accountItem = UIBarButtonItem(customView: account)
        let tabs = UIBarButtonItem(image: UIImage(systemName: "square.on.square"), primaryAction: UIAction { [weak self, weak owner] _ in
            guard let self, let nav = owner?.navigationController as? WMFComponentNavigationController else { return }
            self.presentTabs(in: nav)
        })
        tabs.tintColor = .label
        tabs.accessibilityLabel = t("标签页") + " (\(articleTabs.tabs.count))"
        tabs.accessibilityIdentifier = "article-tabs-button"
        owner.navigationItem.rightBarButtonItems = [accountItem, tabs]
    }
    private func presentAccount(_ site: WMFTianyiSite) {
        guard let tab = tabController else { return }
        let view = TianyiAccountView(site: site, session: session) { [weak tab] in tab?.dismiss(animated: true) }
        tab.present(TianyiHostingContainer(rootView: view), animated: true)
    }
    private func presentTabs(in nav: WMFComponentNavigationController) {
        guard let tab = tabController else { return }
        let view = TianyiArticleTabsView(tabs: articleTabs, select: { [weak self, weak tab, weak nav] id in
            tab?.dismiss(animated: true) { if let nav { self?.selectArticleTab(id, in: nav) } }
        }, close: { [weak self, weak nav] id in
            guard let self else { return }
            let isVisible = nav?.topViewController.map { self.articleTabIDs[ObjectIdentifier($0)] == id } == true
            self.articleTabs.close(id)
            for owner in self.navigationControllers {
                let kept = owner.viewControllers.filter { self.articleTabIDs[ObjectIdentifier($0)] != id }
                if kept.count != owner.viewControllers.count { owner.setViewControllers(kept, animated: false) }
            }
            if isVisible, let nav {
                if let next = self.articleTabs.selected { self.selectArticleTab(next, in: nav) }
                else { nav.popToRootViewController(animated: false) }
            }
        }, newTab: { [weak self, weak tab] in
            tab?.dismiss(animated: true) {
                guard let self, let search = self.navigationControllers.dropFirst().first else { return }
                search.popToRootViewController(animated: false)
                if #available(iOS 18.0, *) { self.tabController?.selectedTab = self.tabController?.tabs[1] }
                else { self.tabController?.selectedIndex = 1 }
            }
        }, done: { [weak tab] in tab?.dismiss(animated: true) })
        tab.present(TianyiHostingContainer(rootView: view), animated: true)
    }
    private func selectArticleTab(_ id: UUID, in nav: WMFComponentNavigationController) {
        guard let entry = articleTabs.tabs.first(where: { $0.id == id }), let root = nav.viewControllers.first else { return }
        for other in navigationControllers where other !== nav && other.viewControllers.count > 1 {
            other.setViewControllers([other.viewControllers[0]], animated: false)
        }
        let controllers = entry.controllers.isEmpty ? entry.pages.map { makePageController($0, tabID: id, nav: nav) } : entry.controllers
        articleTabs.selected = id
        if let page = entry.page { library.visit(page) }
        articleTabs.update(id, pages: entry.pages, controllers: controllers)
        nav.setViewControllers([root] + controllers, animated: false)
    }
    private func show(_ page: WMFTianyiPage, in nav: WMFComponentNavigationController, tabID: UUID? = nil) {
        let id = tabID ?? articleTabs.create(page)
        articleTabs.selected = id
        nav.pushViewController(makePageController(page, tabID: id, nav: nav), animated: true)
    }
    private func makePageController(_ page: WMFTianyiPage, tabID: UUID, nav: WMFComponentNavigationController) -> UIViewController {
        let host: UIViewController
        if ["Special:", "特殊:", "Category:", "分类:", "Talk:", "讨论:"].contains(where: { page.title.hasPrefix($0) }) {
            host = TianyiHostingContainer(rootView: TianyiSiteView(url: page.url))
        } else {
            let toolbar = TianyiArticleToolbarController(pageURL: page.url)
            let reader = TianyiReaderView(page: page, toolbar: toolbar) { [weak self] linked in
                guard let self, let current = self.tabController?.selectedViewController as? WMFComponentNavigationController else { return }
                self.show(linked, in: current, tabID: tabID)
            }.environmentObject(library).environmentObject(session)
            host = TianyiReaderViewController(rootView: reader, toolbar: toolbar)
        }
        pages[ObjectIdentifier(host)] = page
        articleTabIDs[ObjectIdentifier(host)] = tabID
        host.title = page.title
        host.navigationItem.largeTitleDisplayMode = .never
        host.hidesBottomBarWhenPushed = UIDevice.current.userInterfaceIdiom != .pad
        configureHeader(host)
        return host
    }
}

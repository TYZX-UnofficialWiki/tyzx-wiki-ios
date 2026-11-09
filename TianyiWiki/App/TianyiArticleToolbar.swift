import UIKit
import SwiftUI
import Combine
import WMFComponents

/// Toolbar layout and custom-image buttons ported from Wikipedia's
/// ArticleToolbarController.swift and IconBarButtonItem.swift (MIT).
/// Only the action routing and theme adapter belong to the Tianyi client.
@MainActor final class TianyiArticleToolbarController: NSObject {
    enum Command { case contents, languages, save, find, larger, smaller, refresh, source, history, comments }
    struct State: Equatable {
        var available: Bool
        var hasContents: Bool
        var saved: Bool
        var saving: Bool
    }
    let commands = PassthroughSubject<Command, Never>()
    let pageURL: URL
    weak var owner: UIViewController?
    private(set) var currentItems: [UIBarButtonItem] = []

    init(pageURL: URL) {
        self.pageURL = pageURL
        super.init()
        update()
    }

    private func item(_ icon: String, label: String, command: Command) -> UIBarButtonItem {
        // Same UIButton/customView construction as upstream IconBarButtonItem.
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: icon), for: .normal)
        button.addAction(UIAction { [weak self] _ in self?.commands.send(command) }, for: .touchUpInside)
        return barItem(button, label: label)
    }
    private func barItem(_ button: UIButton, label: String) -> UIBarButtonItem {
        button.tintColor = .label // Upstream's iOS 26 IconBarButtonItem tint.
        button.accessibilityLabel = label
        let item = UIBarButtonItem(customView: button)
        item.accessibilityLabel = label
        return item
    }
    private func action(_ key: String, symbol: String, command: Command) -> UIAction {
        UIAction(title: t(key), image: UIImage(systemName: symbol)) { [weak self] _ in self?.commands.send(command) }
    }
    private lazy var tocItem = item("toc", label: t("词条目录"), command: .contents)
    private lazy var languagesButton = item("language", label: t("词条语言"), command: .languages)
    private lazy var saveButton = item("save", label: t("收藏词条"), command: .save)
    private lazy var findInPageButton = item("find-in-page", label: t("词条内查找"), command: .find)
    private lazy var themeButton: UIBarButtonItem = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "font-size"), for: .normal)
        button.menu = UIMenu(children: [action("放大字号", symbol: "textformat.size.larger", command: .larger), action("缩小字号", symbol: "textformat.size.smaller", command: .smaller)])
        button.showsMenuAsPrimaryAction = true
        return barItem(button, label: t("阅读选项"))
    }()
    private lazy var moreButton: UIBarButtonItem = {
        let button = UIButton(type: .system)
        button.setImage(WMFSFSymbolIcon.for(symbol: .ellipsis)?.withConfiguration(UIImage.SymbolConfiguration(weight: .light)), for: .normal)
        let share = UIAction(title: t("分享词条"), image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in self?.share() }
        button.menu = UIMenu(options: .displayInline, children: [
            action("作者与修订历史", symbol: "clock.arrow.circlepath", command: .history),
            action("评论与讨论", symbol: "bubble.left.and.bubble.right", command: .comments), share,
            action("刷新正文", symbol: "arrow.clockwise", command: .refresh),
            action("打开原网页", symbol: "safari", command: .source)
        ])
        button.showsMenuAsPrimaryAction = true
        return barItem(button, label: t("更多"))
    }()
    private var flexibleSpaceToolbarItem: UIBarButtonItem {
        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }
    private func update() {
        // Copied from ArticleToolbarController.update(): the flexible space is the
        // system toolbar's separator between the standalone TOC and trailing group.
        if #available(iOS 26.0, *) {
            currentItems = [tocItem, flexibleSpaceToolbarItem, languagesButton, saveButton, findInPageButton, themeButton, moreButton]
        } else {
            currentItems = [flexibleSpaceToolbarItem, tocItem, flexibleSpaceToolbarItem, languagesButton, flexibleSpaceToolbarItem, saveButton, flexibleSpaceToolbarItem, findInPageButton, flexibleSpaceToolbarItem, themeButton, flexibleSpaceToolbarItem, moreButton, flexibleSpaceToolbarItem]
        }
        owner?.toolbarItems = currentItems
    }
    func update(state: State) {
        func enable(_ item: UIBarButtonItem, _ enabled: Bool) {
            item.isEnabled = enabled
            (item.customView as? UIButton)?.isEnabled = enabled
        }
        enable(tocItem, state.hasContents)
        enable(saveButton, state.available && !state.saving)
        enable(findInPageButton, state.available)
        let title = t(state.saved ? "取消收藏" : "收藏词条")
        saveButton.accessibilityLabel = title
        saveButton.customView?.accessibilityLabel = title
        (saveButton.customView as? UIButton)?.setImage(UIImage(named: state.saved ? "save-filled" : "save"), for: .normal)
    }
    private func share() {
        guard let owner else { return }
        let activity = UIActivityViewController(activityItems: [pageURL], applicationActivities: nil)
        activity.popoverPresentationController?.barButtonItem = moreButton
        owner.present(activity, animated: true)
    }
}

@MainActor protocol TianyiArticleToolbarHosting: AnyObject {}

/// Like upstream ArticleViewController, installs items on the navigation
/// controller's own UIToolbar. No SwiftUI glass capsule or extra bottom inset.
@MainActor class TianyiHostingContainer<Content: View>: UIViewController {
    private let hosting: WMFComponentHostingController<Content>
    init(rootView: Content) {
        hosting = WMFComponentHostingController(rootView: rootView)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)
    }
}

@MainActor final class TianyiReaderViewController<Content: View>: TianyiHostingContainer<Content>, TianyiArticleToolbarHosting {
    private let articleToolbar: TianyiArticleToolbarController
    init(rootView: Content, toolbar: TianyiArticleToolbarController) {
        articleToolbar = toolbar
        super.init(rootView: rootView)
        toolbar.owner = self
        toolbarItems = toolbar.currentItems
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        toolbarItems = articleToolbar.currentItems
        navigationController?.setToolbarHidden(false, animated: false)
    }
}

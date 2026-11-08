import SwiftUI
import WebKit
import WMFData
import WMFComponents

@MainActor final class TianyiArticleViewModel: ObservableObject {
    @Published var article: WMFTianyiArticle?
    @Published var loading = false
    @Published var offline = false
    @Published var error: String?
    let page: WMFTianyiPage
    init(page: WMFTianyiPage) { self.page = page }
    func load(library: TianyiLibrary) async {
        loading = true; error = nil; offline = false
        defer { loading = false }
        // Show explicitly saved content immediately, including without a network.
        if library.contains(page), let cached = try? await library.cache.load(page) {
            article = cached; offline = true
            library.visit(page)
            return
        }
        do {
            let result = try await WMFTianyiDataController.shared.article(page)
            try Task.checkCancellation(); article = result
            library.visit(page)
        } catch { if !Task.isCancelled { self.error = tianyiErrorDescription(error) } }
    }
    func refresh(library: TianyiLibrary) async {
        loading = true; error = nil
        defer { loading = false }
        do {
            let result = try await WMFTianyiDataController.shared.article(page)
            try Task.checkCancellation()
            if library.contains(page) { try await library.cache.save(result, for: page) }
            article = result; offline = false
        } catch { if !Task.isCancelled { self.error = tianyiErrorDescription(error) } }
    }
}

struct TianyiReaderView: View {
    @AppStorage("tianyiInterface") private var interface = TianyiL10n.defaultLanguage
    let page: WMFTianyiPage
    let open: @MainActor @Sendable (WMFTianyiPage) -> Void
    @StateObject private var model: TianyiArticleViewModel
    @EnvironmentObject private var library: TianyiLibrary
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("readerZoom") private var zoom = 1.0
    @State private var showContents = false
    @State private var showLanguages = false
    @State private var anchor = ""
    @State private var scrollRequest = UUID()
    @State private var saving = false
    init(page: WMFTianyiPage, open: @escaping @MainActor @Sendable (WMFTianyiPage) -> Void) {
        self.page = page; self.open = open
        _model = StateObject(wrappedValue: TianyiArticleViewModel(page: page))
    }
    var body: some View {
        VStack(spacing: 0) {
            if model.loading { ProgressView().padding(8) }
            if model.offline { Text(t("正在阅读已保存正文 · 图片与媒体需联网")).font(.caption).foregroundStyle(.secondary).padding(8) }
            if let error = model.error {
                VStack(spacing: 8) {
                    Text(error).font(.subheadline).foregroundStyle(.secondary)
                    Button(t("重试")) { Task { await model.refresh(library: library) } }
                    Button(t("打开原网页")) { openURL(page.url) }
                    Button(t("浏览此语言站首页")) { open(WMFTianyiPage(title: "Special:MainPage", site: page.site)) }
                }.padding()
            }
            if let error = library.storageError { Text(error).font(.caption).foregroundStyle(.red) }
            if let article = model.article {
                TianyiArticleWebView(article: article, page: page, zoom: zoom, dark: colorScheme == .dark, anchor: anchor, scrollRequest: scrollRequest, open: open)
            } else if !model.loading && model.error == nil {
                ContentUnavailableView(t("正在准备词条"), systemImage: "book")
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button { showContents = true } label: { Image(systemName: "list.bullet") }.accessibilityLabel(t("词条目录"))
                    .disabled(model.article?.sections.isEmpty != false)
                Spacer()
                Button { showLanguages = true } label: { Image(systemName: "globe") }
                    .accessibilityLabel(t("词条语言"))
                Spacer()
                Button {
                    saving = true
                    Task { await library.toggle(page, article: model.article); saving = false }
                } label: { Image(systemName: library.contains(page) ? "bookmark.fill" : "bookmark") }
                    .accessibilityLabel(library.contains(page) ? t("取消收藏") : t("收藏词条"))
                    .disabled(model.article == nil || saving)
                Spacer()
                Menu {
                    Button(t("放大字号")) { zoom = min(1.8, zoom + 0.1) }
                    Button(t("缩小字号")) { zoom = max(0.8, zoom - 0.1) }
                    Button(t("刷新正文")) { Task { await model.refresh(library: library) } }
                    Button(t("打开原网页")) { openURL(page.url) }
                    Button(t("作者与修订历史")) {
                        var parts = URLComponents(url: page.url, resolvingAgainstBaseURL: false)!
                        parts.queryItems?.append(URLQueryItem(name: "action", value: "history"))
                        if let url = parts.url { openURL(url) }
                    }
                } label: { Image(systemName: "textformat.size") }.accessibilityLabel(t("阅读选项"))
                Spacer()
                ShareLink(item: page.url) { Image(systemName: "square.and.arrow.up") }.accessibilityLabel(t("分享词条"))
            }.font(.title3).padding(.horizontal, 28).padding(.vertical, 16).background(.bar)
        }
        .sheet(isPresented: $showContents) {
            VStack {
                HStack { Text(t("词条目录")).font(.headline); Spacer(); Button(t("完成")) { showContents = false } }.padding()
                List(model.article?.sections ?? []) { section in
                    Button((try? HtmlUtils.stringFromHTML(section.line)) ?? section.line) {
                        anchor = section.anchor; scrollRequest = UUID(); showContents = false
                    }
                }
            }.presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showLanguages) {
            VStack {
                HStack { Text(t("词条语言")).font(.headline); Spacer(); Button(t("完成")) { showLanguages = false } }.padding()
                List {
                    Section(t("词条语言")) {
                        ForEach(model.article?.translatedPages ?? []) { linked in
                            Button { showLanguages = false; open(linked) } label: {
                                VStack(alignment: .leading) { Text(linked.site.name); Text(linked.title).font(.caption).foregroundStyle(.secondary) }
                            }
                        }
                        if model.article?.translatedPages.isEmpty != false { Text(t("此词条暂无其他语言版本。")) }
                    }
                    Section(t("浏览其他语言站")) {
                        ForEach(WMFTianyiSite.allCases) { site in
                            Button(site.name) { showLanguages = false; open(WMFTianyiPage(title: "Special:MainPage", site: site)) }
                        }
                    }
                }
            }.presentationDetents([.medium, .large])
        }
        .task { await model.load(library: library) }
    }
}

struct TianyiArticleWebView: UIViewRepresentable {
    let article: WMFTianyiArticle
    let page: WMFTianyiPage
    let zoom: Double
    let dark: Bool
    let anchor: String
    let scrollRequest: UUID
    let open: @MainActor @Sendable (WMFTianyiPage) -> Void
    @Environment(\.openURL) private var openURL
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        config.websiteDataStore = .nonPersistent()
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.isOpaque = false; web.backgroundColor = .systemBackground
        return web
    }
    func updateUIView(_ web: WKWebView, context: Context) {
        context.coordinator.parent = self
        web.pageZoom = zoom
        let identity = "\(page.id):\(article.revid):\(dark)"
        if context.coordinator.identity != identity {
            context.coordinator.identity = identity
            web.loadHTMLString(document, baseURL: page.site.baseURL)
        }
        if context.coordinator.scrollRequest != scrollRequest {
            context.coordinator.scrollRequest = scrollRequest
            if let data = try? JSONEncoder().encode(anchor), let literal = String(data: data, encoding: .utf8) {
                web.evaluateJavaScript("document.getElementById(\(literal))?.scrollIntoView({behavior:'smooth'})", completionHandler: nil)
            }
        }
    }
    private var document: String {
        let foreground = dark ? "#e7e9ed" : "#202122"
        let background = dark ? "#101418" : "#ffffff"
        let canonical = page.url.absoluteString.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "\"", with: "&quot;")
        return """
        <!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src https: data:; style-src 'unsafe-inline' https:; media-src https:; script-src 'none'; frame-src 'none'; form-action 'none'; base-uri 'none'">
        <style>:root{color-scheme:\(dark ? "dark" : "light")}body{font:17px/1.8 -apple-system,BlinkMacSystemFont,sans-serif;margin:0 auto;padding:20px;max-width:760px;color:\(foreground);background:\(background);overflow-wrap:anywhere}a{color:\(dark ? "#88a3e8" : "#36c")}img,video{max-width:100%;height:auto}table{max-width:100%;display:block;overflow-x:auto;border-collapse:collapse}td,th{padding:6px;border:1px solid #8884}.infobox{float:none!important;width:100%!important;box-sizing:border-box}.mw-editsection,.mw-empty-elt{display:none}h1,h2,h3{line-height:1.4}.mw-heading{margin-top:1.5em}blockquote{margin:1em 0;padding-left:1em;border-left:3px solid #8884}footer{font-size:13px;border-top:1px solid #8884;margin-top:30px;padding-top:16px;color:#72777d}</style>
        </head><body>\(article.text)<footer>\(t("来源"))：\(t("天一维基")) · \(t("修订")) \(article.revid)<br>\(t("正文及媒体许可请查看")) <a href="\(canonical)">\(t("原页面"))</a> \(t("与页面修订历史；保留原作者署名与引用。"))</footer></body></html>
        """
    }
    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: TianyiArticleWebView
        var identity = ""
        var scrollRequest: UUID?
        init(_ parent: TianyiArticleWebView) { self.parent = parent }
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard action.navigationType == .linkActivated, let url = action.request.url else { return .allow }
            if let fragment = url.fragment, !fragment.isEmpty,
               let current = webView.url, url.deletingPathExtension().path == current.deletingPathExtension().path,
               url.host == current.host { return .allow }
            if let site = WMFTianyiSite.matching(url), let title = site.title(in: url) {
                let action = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "action" }?.value
                if action == nil || action == "view" { parent.open(WMFTianyiPage(title: title, site: site)) }
                else { parent.openURL(url) }
            } else if ["https", "http", "mailto", "tel"].contains(url.scheme?.lowercased() ?? "") { parent.openURL(url) }
            return .cancel
        }
    }
}

/// Complete web fallback for special/category pages, with external links routed to the system.
struct TianyiSiteView: UIViewRepresentable {
    let url: URL
    @Environment(\.openURL) private var openURL
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.allowsInlineMediaPlayback = true
        // The site's play control supplies the user gesture for sound; retain WebKit's
        // autoplay policy instead of starting music without a tap.
        config.mediaTypesRequiringUserActionForPlayback = .all
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.allowsBackForwardNavigationGestures = true; web.load(URLRequest(url: url))
        return web
    }
    func updateUIView(_ uiView: WKWebView, context: Context) { context.coordinator.parent = self }
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.stopLoading()
        uiView.evaluateJavaScript("document.querySelectorAll('audio,video').forEach(media => media.pause())", completionHandler: nil)
        uiView.navigationDelegate = nil
        uiView.loadHTMLString("", baseURL: nil)
    }
    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: TianyiSiteView
        init(_ parent: TianyiSiteView) { self.parent = parent }
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard let url = action.request.url else { return .cancel }
            if WMFTianyiSite.matching(url) != nil { return .allow }
            if ["https", "http", "mailto", "tel"].contains(url.scheme?.lowercased() ?? "") { parent.openURL(url) }
            return .cancel
        }
    }
}

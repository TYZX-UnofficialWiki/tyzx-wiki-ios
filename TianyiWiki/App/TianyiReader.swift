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
        if let cached = try? await library.cache.load(page) {
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
    @State private var showComments = false
    @State private var commentsAvailable: Bool?
    @StateObject private var badApple = TianyiBadApplePlayer()
    @Environment(\.scenePhase) private var scenePhase
    private var isBadApple: Bool { page.title.replacingOccurrences(of: "_", with: " ").lowercased() == "bad apple!!" }
    init(page: WMFTianyiPage, open: @escaping @MainActor @Sendable (WMFTianyiPage) -> Void) {
        self.page = page; self.open = open
        _model = StateObject(wrappedValue: TianyiArticleViewModel(page: page))
    }
    var body: some View {
        VStack(spacing: 0) {
            if model.loading { ProgressView().padding(8) }
            if model.offline { Text(t(isBadApple && badApple.ready ? "已缓存正文、音乐与动画，可离线播放" : "正在阅读已保存正文 · 图片与媒体需联网")).font(.caption).foregroundStyle(.secondary).padding(8) }
            if let error = model.error {
                VStack(spacing: 8) {
                    Text(error).font(.subheadline).foregroundStyle(.secondary)
                    Button(t("重试")) { Task { await model.refresh(library: library) } }
                    Button(t("打开原网页")) { openURL(page.url) }
                    Button(t("浏览此语言站首页")) { open(WMFTianyiPage(title: "Special:MainPage", site: page.site)) }
                }.padding()
            }
            if let error = library.storageError { Text(error).font(.caption).foregroundStyle(.red) }
            if isBadApple {
                HStack {
                    Button(badApple.playing ? t("暂停") : t("播放")) { badApple.toggle() }.disabled(!badApple.ready)
                    Text(String(format: "%d:%02d / 3:39", Int(badApple.time)/60, Int(badApple.time)%60)).monospacedDigit()
                    Button(t("阅读词条")) { badApple.stop() }
                }.padding(10)
                if let error = badApple.error { Text(error).font(.caption); Button(t("重试")) { Task { await badApple.prepare() } } }
                if !badApple.ready { Button(t("缓存彩蛋供离线播放")) { Task { await badApple.prepare() } } }
            }
            if let article = model.article {
                TianyiArticleWebView(article: article, page: page, zoom: zoom, dark: colorScheme == .dark, anchor: anchor, scrollRequest: scrollRequest, frames: badApple.frames, playbackTime: badApple.time, animating: badApple.playing, open: open)
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
                Button { commentsAvailable = nil; showComments = true } label: { Image(systemName: "text.bubble") }.accessibilityLabel(t("评论与讨论"))
                Spacer()
                ShareLink(item: page.url) { Image(systemName: "square.and.arrow.up") }.accessibilityLabel(t("分享词条"))
            }.font(.title3).padding(.horizontal, 28).padding(.vertical, 16).modifier(TianyiGlassBar())
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
        .sheet(isPresented: $showComments) {
            VStack {
                HStack {
                    Text(t("评论与讨论")).font(.headline)
                    Spacer()
                    Button(t("完成")) { showComments = false }
                }.padding()
                if commentsAvailable == false {
                    ContentUnavailableView(t("此词条关闭了评论功能"), systemImage: "text.bubble")
                } else {
                    TianyiSiteView(url: page.url, commentsOnly: true, onCommentsAvailable: { commentsAvailable = $0 })
                        .opacity(commentsAvailable == true ? 1 : 0)
                        .overlay { if commentsAvailable == nil { ProgressView().accessibilityIdentifier("comments-loading") } }
                }
            }
        }
        .task {
            await model.load(library: library)
            if isBadApple, let article = model.article {
                do { try await library.cache.save(article, for: page) } catch { library.storageError = error.localizedDescription }
            }
        }
        .task { if isBadApple { await badApple.prepare() } }
        .task {
            while !Task.isCancelled {
                if isBadApple { badApple.tick() }
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
        .onDisappear { badApple.pause() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { badApple.pause() } }
    }
}

struct TianyiArticleWebView: UIViewRepresentable {
    let article: WMFTianyiArticle
    let page: WMFTianyiPage
    let zoom: Double
    let dark: Bool
    let anchor: String
    let scrollRequest: UUID
    var frames: String? = nil
    var playbackTime: Double = 0
    var animating: Bool = false
    let open: @MainActor @Sendable (WMFTianyiPage) -> Void
    @Environment(\.openURL) private var openURL
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        config.websiteDataStore = .nonPersistent()
        config.userContentController.addUserScript(WKUserScript(source: Self.interactions, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.isOpaque = false; web.backgroundColor = .systemBackground
        return web
    }
    func updateUIView(_ web: WKWebView, context: Context) {
        context.coordinator.parent = self
        if context.coordinator.textSize != zoom {
            context.coordinator.textSize = zoom
            context.coordinator.applyTextSize(web)
        }
        let identity = "\(page.id):\(article.revid):\(dark)"
        if context.coordinator.identity != identity {
            context.coordinator.identity = identity
            web.loadHTMLString(document, baseURL: page.site.baseURL)
        }
        if let frames, context.coordinator.frames != frames {
            context.coordinator.frames = frames
            web.evaluateJavaScript("window.baData = " + frames + ";window.baBits=Uint8Array.from(atob(baData.data),c=>c.charCodeAt(0));", completionHandler: nil)
        }
        if context.coordinator.lastTime != playbackTime || context.coordinator.lastActive != animating {
            context.coordinator.lastTime = playbackTime; context.coordinator.lastActive = animating
            web.evaluateJavaScript("window.baDraw?.(\(playbackTime),\(animating ? "true" : "false"))", completionHandler: nil)
        }
        if context.coordinator.scrollRequest != scrollRequest {
            context.coordinator.scrollRequest = scrollRequest
            if let data = try? JSONEncoder().encode(anchor), let literal = String(data: data, encoding: .utf8) {
                web.evaluateJavaScript("document.getElementById(\(literal))?.scrollIntoView({behavior:'smooth'})", completionHandler: nil)
            }
        }
    }
    static let interactions = """
    document.addEventListener('click', e=>{let n=e.target.closest('.heimu,.tyzx-black-curtain,.spoiler');if(n)n.classList.toggle('revealed')});
    window.baDraw=(time,active)=>{
      let body=document.querySelector('.mw-parser-output')||document.body;
      if(!active){body.querySelectorAll('.ba-letter').forEach(n=>n.classList.remove('ba-black'));return;}
      if(!window.baBits)return;
      if(!window.baWrapped){let w=document.createTreeWalker(body,NodeFilter.SHOW_TEXT),nodes=[],n;while(n=w.nextNode())if(n.textContent.trim()&&!n.parentElement.closest('script,style,h1,h2,h3,footer'))nodes.push(n);nodes.forEach(n=>{let f=document.createDocumentFragment();for(let c of Array.from(n.textContent)){let s=document.createElement('span');s.className='ba-letter';s.textContent=c;f.append(s)}n.replaceWith(f)});window.baWrapped=true;}
      const area=body.getBoundingClientRect(),top=Math.max(area.top,0),height=Math.max(1,Math.min(area.bottom,innerHeight)-top),frame=Math.min(baData.frameCount-1,Math.floor(time*baData.fps));
      body.querySelectorAll('.ba-letter').forEach(n=>{let r=n.getBoundingClientRect(),x=r.x+r.width/2,y=r.y+r.height/2,p=Math.min(24,Math.max(0,Math.floor((y-top)*25/height)))*80+Math.min(79,Math.max(0,Math.floor((x-area.left)*80/area.width)));n.classList.toggle('ba-black',y>=top&&y<top+height&&!!(baBits[frame*250+(p>>3)]&(128>>(p&7))))});
    };
    """
    private var document: String {
        let foreground = dark ? "#e7e9ed" : "#202122"
        let background = dark ? "#101418" : "#ffffff"
        let canonical = page.url.absoluteString.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "\"", with: "&quot;")
        return """
        <!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src https: data:; style-src 'unsafe-inline' https:; media-src https:; script-src 'none'; frame-src 'none'; form-action 'none'; base-uri 'none'">
        <style>:root{color-scheme:\(dark ? "dark" : "light")}body{font:\(17 * zoom)px/1.8 -apple-system,BlinkMacSystemFont,sans-serif;margin:0 auto;padding:20px;max-width:760px;color:\(foreground);background:\(background);overflow-wrap:anywhere}a{color:\(dark ? "#88a3e8" : "#36c")}img,video{max-width:100%;height:auto}table{max-width:100%;display:block;overflow-x:auto;border-collapse:collapse}td,th{padding:6px;border:1px solid #8884}.infobox{float:none!important;width:100%!important;box-sizing:border-box}.mw-editsection,.mw-empty-elt{display:none}h1,h2,h3{line-height:1.4}.mw-heading{margin-top:1.5em}blockquote{margin:1em 0;padding-left:1em;border-left:3px solid #8884}footer{font-size:13px;border-top:1px solid #8884;margin-top:30px;padding-top:16px;color:#72777d} :root{--color-base:\(foreground);--color-subtle:\(dark ? "#b8bec7" : "#54595d");--background-color-base:\(background);--background-color-neutral-subtle:\(dark ? "#20252b" : "#f8f9fa");--color-progressive:#88a3e8}\(dark ? ".mw-parser-output [style*=background],.infobox,.infobox th,.infobox td,.mw-parser-output .tyzx-infobox,.mw-parser-output .tyzx-infobox th,.mw-parser-output .tyzx-infobox td,.thumbinner,figure,figcaption,.thumbcaption{background-color:#20252b!important;color:#e7e9ed!important}" : "") .heimu,.tyzx-black-curtain,.spoiler,.ba-black{background:#000!important;color:#000!important}.heimu:hover,.tyzx-black-curtain:hover,.revealed,.ba-black:hover{color:#fff!important}
        </style>
        </head><body>\(article.text)<footer>\(t("来源"))：\(t("天一维基")) · \(t("修订")) \(article.revid)<br>\(t("正文及媒体许可请查看")) <a href="\(canonical)">\(t("原页面"))</a> \(t("与页面修订历史；保留原作者署名与引用。"))</footer></body></html>
        """
    }
    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: TianyiArticleWebView
        var textSize: Double?
        var lastTime = -1.0
        var lastActive = false
        var frames: String?
        var identity = ""
        var scrollRequest: UUID?
        init(_ parent: TianyiArticleWebView) { self.parent = parent }
        func applyTextSize(_ web: WKWebView) {
            web.evaluateJavaScript("document.body.style.fontSize='\(17 * parent.zoom)px'", completionHandler: nil)
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            frames = nil
            applyTextSize(webView)
        }
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
    var commentsOnly = false
    var onCommentsAvailable: (@MainActor (Bool) -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        if commentsOnly {
            config.userContentController.add(context.coordinator, name: "commentStatus")
            // DOM readiness must not wait for unrelated images, audio or animation downloads.
            config.userContentController.addUserScript(WKUserScript(source: Self.detectComments, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        }
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.allowsInlineMediaPlayback = true
        // The site's play control supplies the user gesture for sound; retain WebKit's
        // autoplay policy instead of starting music without a tap.
        config.mediaTypesRequiringUserActionForPlayback = .all
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        config.userContentController.addUserScript(WKUserScript(source: Self.cleanPage, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        web.allowsBackForwardNavigationGestures = true; web.load(URLRequest(url: url))
        return web
    }
    static let detectComments = """
    (() => {
      let done = false;
      const check = () => {
        const region = document.querySelector('.tyzx-comments,#comments,#comment-form,.comment-form,.comments-block');
        if (!region || done) return false;
        done = true;
        region.setAttribute('data-tianyi-comments-root', '');
        for (let node = region; node && node !== document.body; node = node.parentElement) {
          node.setAttribute('data-tianyi-comments-path', '');
        }
        // Keep the original DOM ancestry and event handlers used by MediaWiki's forms.
        const style = document.createElement('style');
        style.textContent = `body.tianyi-comments-only :not([data-tianyi-comments-path]):not([data-tianyi-comments-root] *):not(.oo-ui-windowManager):not(.oo-ui-windowManager *):not(dialog):not(dialog *){display:none!important}
          [data-tianyi-comments-path]{min-height:0!important;margin-top:0!important;padding-top:0!important}
          [data-tianyi-comments-root]{display:block!important;padding:16px!important}`;
        document.head.appendChild(style);
        document.body.classList.add('tianyi-comments-only');
        window.scrollTo(0, 0);
        window.webkit.messageHandlers.commentStatus.postMessage(true);
        return true;
      };
      if (!check()) {
        const observer = new MutationObserver(() => { if (check()) observer.disconnect(); });
        observer.observe(document.body, {childList:true, subtree:true});
        setTimeout(() => { observer.disconnect(); if (!done) window.webkit.messageHandlers.commentStatus.postMessage(false); }, 2500);
      }
    })();
    """
    static let cleanPage = """
    let style=document.createElement('style');style.textContent='#siteNotice,#centralNotice,.header-container,.mw-footer,.vector-header-container,.vector-column-start,.vector-column-end,.vector-page-toolbar,.minerva-page-actions,.tyzx-announcement-carousel,.tyzx-announcements{display:none!important}body{padding:0!important}';document.head.append(style);
    """
    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.applyTheme(uiView)
    }
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "commentStatus")
        uiView.stopLoading()
        uiView.evaluateJavaScript("document.querySelectorAll('audio,video').forEach(media => media.pause())", completionHandler: nil)
        uiView.navigationDelegate = nil
        uiView.loadHTMLString("", baseURL: nil)
    }
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: TianyiSiteView
        init(_ parent: TianyiSiteView) { self.parent = parent }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "commentStatus", let available = message.body as? Bool else { return }
            parent.onCommentsAvailable?(available)
        }
        func applyTheme(_ web: WKWebView) {
            let dark = parent.colorScheme == .dark
            web.evaluateJavaScript("document.documentElement.classList.toggle('skin-theme-clientpref-night',\(dark));document.documentElement.classList.toggle('skin-theme-clientpref-day',\(!dark));document.documentElement.style.colorScheme='\(dark ? "dark" : "light")';let s=document.getElementById('native-theme')||document.head.appendChild(document.createElement('style'));s.id='native-theme';s.textContent='\(dark ? "html{--background-color-base:#101418;--background-color-neutral-subtle:#20252b;--color-base:#e7e9ed;--color-subtle:#b8bec7}body,#content,.mw-body,.minerva__tab-container,.tyzx-comments{background:#101418!important;color:#e7e9ed!important}.th-panel,.th-hero,.thumbcaption,figcaption,th,td,[style*=background]{background-color:#20252b!important;color:#e7e9ed!important}" : "")';", completionHandler:nil)
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            applyTheme(webView)
        }

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard let url = action.request.url else { return .cancel }
            if action.targetFrame?.isMainFrame == false { return .allow }
            if WMFTianyiSite.matching(url) != nil { return .allow }
            if ["https", "http", "mailto", "tel"].contains(url.scheme?.lowercased() ?? "") { parent.openURL(url) }
            return .cancel
        }
    }
}

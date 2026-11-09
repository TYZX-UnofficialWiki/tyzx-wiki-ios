import SwiftUI
import WMFData
import WMFComponents

private struct TianyiPageButton: View {
    let title: String
    let detail: String?
    let action: @MainActor () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(Font(WMFFont.for(.semiboldHeadline))).foregroundStyle(.primary)
                    if let detail { Text(detail).font(Font(WMFFont.for(.subheadline))).foregroundStyle(.secondary).lineLimit(3) }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }.padding(.vertical, 6)
        }.buttonStyle(.plain)
    }
}
struct TianyiExploreView: View {
    @AppStorage("tianyiInterface") private var interface = TianyiL10n.defaultLanguage
    let open: @MainActor @Sendable (WMFTianyiPage) -> Void
    @AppStorage("tianyiSite") private var site = WMFTianyiSite.zh
    @State private var recent: [WMFTianyiChange] = []
    @State private var error: String?
    @State private var loading = false
    @State private var randomLoading = false
    private var topics: [(String, String, String)] {
        site == .zh ? [(t("校园总览"), "江苏省天一中学", "building.2"), (t("学校历史"), "学校历史", "clock"), (t("校园地点"), "Category:区域与地点", "map"), (t("学生社团"), "Category:学生社团", "person.3"), (t("校园活动"), "樱花节", "leaf"), (t("全部词条"), "Special:AllPages", "square.grid.2x2")] : [(t("维基首页"), "Special:MainPage", "globe"), (t("全部词条"), "Special:AllPages", "square.grid.2x2")]
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                TianyiHomeContent(open: open)
                HStack { Text(t("最近更改")).font(Font(WMFFont.for(.boldTitle3))); Spacer(); if loading { ProgressView() } }
                if let error { Text(error).font(.subheadline).foregroundStyle(.secondary); Button(t("重新加载")) { Task { await load() } } }
                LazyVStack(spacing: 0) {
                    ForEach(recent) { change in
                        TianyiPageButton(title: change.title, detail: ISO8601DateFormatter().date(from: change.timestamp)?.formatted(date: .abbreviated, time: .shortened)) {
                            open(WMFTianyiPage(title: change.title, site: site))
                        }.padding(.vertical, 8)
                        Divider()
                    }
                }
                Text(t("学生共同编写 · 不代表学校官方立场\n基于 Wikipedia iOS 开源项目开发"))
                    .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.vertical)
            }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Color(.systemGroupedBackground))
            .task(id: site) { await load() }.refreshable { await load() }
    }
    private func load() async {
        loading = true; error = nil
        if let data = UserDefaults.standard.data(forKey: "recent-" + site.rawValue), let saved = try? JSONDecoder().decode([WMFTianyiChange].self, from: data) { recent = saved }
        defer { if !Task.isCancelled { loading = false } }
        do { await TianyiSession.shared.synchronizeCookies(); let changes = try await WMFTianyiDataController.shared.recent(site: site); try Task.checkCancellation(); recent = changes; if let data = try? JSONEncoder().encode(changes) { UserDefaults.standard.set(data, forKey: "recent-" + site.rawValue) } }
        catch { if !Task.isCancelled { self.error = tianyiErrorDescription(error) } }
    }
    private func random() async {
        randomLoading = true; defer { randomLoading = false }
        do { await TianyiSession.shared.synchronizeCookies(); open(WMFTianyiPage(title: try await WMFTianyiDataController.shared.random(site: site), site: site)) }
        catch { self.error = tianyiErrorDescription(error) }
    }
}

struct TianyiSearchView: View {
    @AppStorage("tianyiInterface") private var interface = TianyiL10n.defaultLanguage
    let open: @MainActor @Sendable (WMFTianyiPage) -> Void
    @AppStorage("tianyiSite") private var site = WMFTianyiSite.zh
    @State private var term = ""
    @State private var hits: [WMFTianyiSearchHit] = []
    @State private var error: String?
    @State private var loading = false
    @State private var completed = false
    @State private var retry = UUID()
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField(t("搜索") + " · " + site.name, text: $term).accessibilityIdentifier("tianyi-search")
                    .submitLabel(.search).autocorrectionDisabled()
                if !term.isEmpty { Button { term = "" } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel(t("清除搜索")) }
            }.padding(12).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12)).padding()
            Picker(t("维基语言"), selection: $site) { ForEach(WMFTianyiSite.allCases) { Text($0.name).tag($0) } }
                .accessibilityIdentifier("search-wiki-language").padding(.horizontal)
            List {
                if loading { HStack { ProgressView(); Text(t("正在搜索…")) } }
                if let error { Text(error); Button(t("重试")) { retry = UUID() } }
                ForEach(hits) { hit in
                    TianyiPageButton(title: hit.title, detail: try? HtmlUtils.stringFromHTML(hit.snippet)) { open(WMFTianyiPage(title: hit.title, site: site)) }
                }
            }.overlay {
                if hits.isEmpty && !loading && error == nil {
                    ContentUnavailableView(completed ? t("没有找到相关词条") : t("搜索校园记忆"), systemImage: "magnifyingglass", description: Text(completed ? t("试试其他关键词。") : t("校园、社团、活动与共同的回忆。")))
                }
            }.scrollDismissesKeyboard(.interactively)
        }.background(Color(.systemGroupedBackground))
        .task(id: "\(site.rawValue)|\(term)|\(retry)") {
            hits = []; error = nil; loading = false; completed = false
            let query = term.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return }
            loading = true
            do {
                try await Task.sleep(for: .milliseconds(350))
                await TianyiSession.shared.synchronizeCookies()
                let result = try await WMFTianyiDataController.shared.search(query, site: site)
                try Task.checkCancellation(); hits = result; completed = true; loading = false
            } catch { if !Task.isCancelled { self.error = tianyiErrorDescription(error); loading = false } }
        }
    }
}

struct TianyiLibraryView: View {
    @AppStorage("tianyiInterface") private var interface = TianyiL10n.defaultLanguage
    let open: @MainActor @Sendable (WMFTianyiPage) -> Void
    @EnvironmentObject private var library: TianyiLibrary
    @State private var history = false
    var body: some View {
        List {
            Picker(t("内容"), selection: $history) { Text(t("离线收藏")).tag(false); Text(t("阅读历史")).tag(true) }.pickerStyle(.segmented)
            ForEach(history ? library.history : library.saved) { page in
                TianyiPageButton(title: page.title, detail: page.site.name) { open(page) }
            }
            if (history ? library.history : library.saved).isEmpty {
                ContentUnavailableView(history ? t("还没有阅读记录") : t("收藏校园的故事"), systemImage: history ? "clock" : "bookmark", description: Text(t("收藏会保存正文供离线阅读；图片和音视频仍需联网。")))
            }
        }
    }
}

struct TianyiSettingsView: View {
    let interfaceChanged: @MainActor @Sendable (String) -> Void
    @AppStorage("tianyiInterface") private var interface = TianyiL10n.defaultLanguage
    @EnvironmentObject private var library: TianyiLibrary
    @AppStorage("tianyiSite") private var site = WMFTianyiSite.zh
    @State private var clearOffline = false
    var body: some View {
        Form {
            Section(t("维基")) {
                Picker(t("界面语言"), selection: $interface) {
                    ForEach(WMFTianyiSite.allCases) { Text($0.name).tag($0.rawValue) }
                }.accessibilityIdentifier("interface-language")
                Text(t("界面语言不限制词条语言，可浏览全部六个站点。")).font(.footnote).foregroundStyle(.secondary)
                Picker(t("维基语言"), selection: $site) { ForEach(WMFTianyiSite.allCases) { Text($0.name).tag($0) } } }
            Section(t("本机数据")) {
                Button(t("清除阅读历史"), role: .destructive) { library.clearHistory() }
                Button(t("删除全部离线收藏"), role: .destructive) { clearOffline = true }
                Text(t("仅缓存匿名可见正文。图片与音视频不保证离线可用。收藏和历史不上传到 Wikimedia。"))
                    .font(.footnote).foregroundStyle(.secondary)
                if let error = library.storageError { Text(error).foregroundStyle(.red) }
            }
            Section(t("关于")) {
                LabeledContent(t("天一维基"), value: "0.2.0")
                Text(t("江苏省天一中学非官方维基，由社区编写，不代表学校或 Wikimedia Foundation 官方立场。"))
                    .font(.footnote)
                Link(t("开源代码与问题反馈"), destination: URL(string: "https://github.com/TYZX-UnofficialWiki/tyzx-wiki-ios")!)
                Link(t("网站隐私政策"), destination: site.pageURL("Project:隐私政策"))
                Text(t("基于 Wikipedia iOS（MIT License）开发。原始著作权 © 2013–2025 Wikimedia Foundation et al. 许可全文随应用附带。正文及媒体授权以各词条声明和历史作者记录为准。"))
                    .font(.footnote).foregroundStyle(.secondary)
                if let license = Bundle.main.url(forResource: "THIRD_PARTY_NOTICES", withExtension: "txt"), let text = try? String(contentsOf: license, encoding: .utf8) {
                    DisclosureGroup(t("开源许可")) { Text(text).font(.caption).textSelection(.enabled) }
                }
            }
        }
        .onChange(of: interface) { _, language in interfaceChanged(language) }
        .confirmationDialog(t("删除全部收藏及离线正文？"), isPresented: $clearOffline, titleVisibility: .visible) {
            Button(t("删除"), role: .destructive) { Task { await library.clearOffline() } }
        }
    }
}

import SwiftUI
import UIKit
import WMFData

@MainActor final class TianyiArticleTabs: ObservableObject {
    struct Tab: Identifiable {
        let id: UUID
        var pages: [WMFTianyiPage]
        var controllers: [UIViewController] = []
        var page: WMFTianyiPage? { pages.last }
    }
    private struct Snapshot: Codable { let id: UUID; let pages: [WMFTianyiPage] }
    @Published private(set) var tabs: [Tab] = []
    @Published var selected: UUID?
    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-TianyiResetTabs") { UserDefaults.standard.removeObject(forKey: "tianyiArticleTabs") }
        #endif
        if let data = UserDefaults.standard.data(forKey: "tianyiArticleTabs"), let stored = try? JSONDecoder().decode([Snapshot].self, from: data) {
            tabs = stored.filter { !$0.pages.isEmpty }.map { Tab(id: $0.id, pages: $0.pages) }
        }
    }
    @discardableResult func create(_ page: WMFTianyiPage) -> UUID {
        let id = UUID()
        tabs.append(Tab(id: id, pages: [page])); selected = id; persist(); return id
    }
    func update(_ id: UUID, pages: [WMFTianyiPage], controllers: [UIViewController]) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[index].pages = pages; tabs[index].controllers = controllers; persist()
    }
    func close(_ id: UUID) {
        tabs.removeAll { $0.id == id }
        if selected == id { selected = tabs.last?.id }
        persist()
    }
    private func persist() {
        if let data = try? JSONEncoder().encode(tabs.map { Snapshot(id: $0.id, pages: $0.pages) }) { UserDefaults.standard.set(data, forKey: "tianyiArticleTabs") }
    }
}

struct TianyiArticleTabsView: View {
    @ObservedObject var tabs: TianyiArticleTabs
    let select: (UUID) -> Void
    let close: (UUID) -> Void
    let newTab: () -> Void
    let done: () -> Void
    var body: some View {
        VStack {
            HStack { Text(t("标签页")).font(.headline); Spacer(); Button(t("完成"), action: done) }.padding()
            if tabs.tabs.isEmpty { ContentUnavailableView(t("暂无标签页"), systemImage: "square.on.square") }
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                    ForEach(tabs.tabs) { tab in
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: tab.id == tabs.selected ? "checkmark.circle.fill" : "doc.text")
                                Spacer()
                                Button { close(tab.id) } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel(t("关闭标签页") + " " + (tab.page?.title ?? ""))
                            }
                            Button { select(tab.id) } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(tab.page?.title ?? "").font(.headline).lineLimit(3)
                                    Text(tab.page?.site.name ?? "").font(.caption).foregroundStyle(.secondary)
                                }.frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
                            }.accessibilityIdentifier("article-tab-" + tab.id.uuidString)
                        }.padding().background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
                    }
                }.padding()
            }
            Button(action: newTab) { Label(t("新建标签页"), systemImage: "plus") }.buttonStyle(.borderedProminent).padding()
        }.background(Color(.systemGroupedBackground))
    }
}

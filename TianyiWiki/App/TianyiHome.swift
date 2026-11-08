import SwiftUI
import WMFData

struct TianyiHomeSection: Decodable, Identifiable {
    struct Link: Decodable { let label: String; let url: URL }
    let title: String
    let text: String
    let links: [Link]
    let images: [String]
    let id: String
}
struct TianyiHomeContent: View {
    let open: @MainActor @Sendable (WMFTianyiPage) -> Void
    @Environment(\.openURL) private var openURL
    private var sections: [TianyiHomeSection] {
        guard let url = Bundle.main.url(forResource: "HomeSnapshot", withExtension: "json"), let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([TianyiHomeSection].self, from: data)) ?? []
    }
    var body: some View {
        ForEach(sections) { section in
            VStack(alignment: .leading, spacing: 14) {
                Text(section.title).font(.title2.bold())
                if section.title == "欢迎来到天一维基" {
                    Image("TianyiWordmark").resizable().scaledToFit().frame(maxHeight: 120)
                }
                ForEach(section.title == "欢迎来到天一维基" ? [] : section.images, id: \.self) { name in
                    Image(name).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 12))
                }
                if !section.text.isEmpty { Text(section.text).font(.body).textSelection(.enabled) }
                if section.title == "欢迎来到天一维基" {
                    Button { open(WMFTianyiPage(title: "江苏省天一中学", site: .zh)) } label: { Label(t("开始阅读"), systemImage: "arrow.right") }.buttonStyle(.borderedProminent)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], alignment: .leading, spacing: 10) {
                    ForEach(Array(section.links.enumerated()), id: \.offset) { _, link in
                        Button(link.label) {
                            if let site = WMFTianyiSite.matching(link.url), let title = site.title(in: link.url) { open(WMFTianyiPage(title: title, site: site)) }
                            else { openURL(link.url) }
                        }.buttonStyle(.bordered).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        }
        Link(t("作者与修订历史"), destination: URL(string: "https://zh-wiki.tyzx.org/index.php?title=首页&action=history")!)
            .font(.footnote)
        Text("首页离线快照 · 2026-11-08").font(.caption).foregroundStyle(.secondary)
    }
}

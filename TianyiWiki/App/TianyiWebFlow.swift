import SwiftUI
import WebKit
import WMFData

@MainActor final class TianyiWebNavigation: ObservableObject {
    weak var web: WKWebView?
    @Published var canGoBack = false
    @Published var loading = true
    @Published var error: String?
    func update(_ web: WKWebView) {
        self.web = web
        canGoBack = web.canGoBack
        loading = web.isLoading
    }
}

struct TianyiWebRequest: Identifiable {
    enum Kind: String { case page, login, register, logout }
    let id = UUID()
    let url: URL
    let title: String
    var kind: Kind = .page
}

/// Keeps the real site's login, QQ verification and privacy forms intact.
/// New-window policy links open separately so the registration form is retained.
struct TianyiWebFlow: View {
    let request: TianyiWebRequest
    let site: WMFTianyiSite
    @ObservedObject var session: TianyiSession
    @StateObject private var navigation = TianyiWebNavigation()
    @State private var child: TianyiWebRequest?
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { navigation.web?.goBack() } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel(t("返回")).disabled(!navigation.canGoBack)
                Text(request.title).font(.headline).lineLimit(1)
                Spacer()
                Button(t("完成")) { dismiss(); Task { await session.refresh(site) } }.accessibilityIdentifier("web-flow-done-" + request.kind.rawValue)
            }.padding()
            if navigation.loading { ProgressView().padding(4) }
            if let error = navigation.error {
                VStack { Text(error); Button(t("重试")) { navigation.error = nil; navigation.web?.reload() } }.padding()
            }
            TianyiSiteView(url: request.url, navigation: navigation,
                onOpenNewWindow: { child = TianyiWebRequest(url: $0, title: t("网页")) },
                onPageLoaded: { Task { await session.refresh(site) } })
                .accessibilityIdentifier("account-web-flow")
        }
        .sheet(item: $child) { next in TianyiWebFlow(request: next, site: site, session: session).id(next.id) }
        .onChange(of: session.revision) { _, _ in
            if request.kind == .logout && session.isAnonymousVerified(site) { dismiss() }
        }
        .onChange(of: session.users[site]?.id) { _, after in
            if (request.kind == .login || request.kind == .register) && after != nil { dismiss() }
        }
    }
}

struct TianyiAccountView: View {
    let site: WMFTianyiSite
    @ObservedObject var session: TianyiSession
    let done: () -> Void
    @State private var flow: TianyiWebRequest?
    private var user: TianyiSession.User? { session.users[site] }
    var body: some View {
        VStack(spacing: 0) {
            HStack { Text(t("账号")).font(.headline); Spacer(); Button(t("完成"), action: done).accessibilityIdentifier("account-done") }.padding()
            if let user {
                HStack {
                    if let avatar = user.avatar { Image(uiImage: avatar).resizable().scaledToFill().frame(width: 52, height: 52).clipShape(Circle()).accessibilityIdentifier("account-avatar") }
                    else { Image(systemName: "person.crop.circle.fill").font(.system(size: 48)) }
                    VStack(alignment: .leading) { Text(user.name).font(.title2.bold()); Text(site.name).foregroundStyle(.secondary) }
                    Spacer()
                }.padding()
            }
            List {
                if let error = session.errors[site] {
                    Section { Text(error); Button(t("重试")) { Task { await session.refresh(site) } } }
                }
                if let user {
                    Section {
                        entry("用户页", "person.crop.square", "User:" + user.name)
                        entry("您的讨论页", "bubble.left", "User talk:" + user.name)
                        entry("通知", "bell", "Special:Notifications")
                        entry("监视列表", "star", "Special:Watchlist")
                    }
                    Section {
                        entry("设置头像", "person.crop.circle.badge.plus", "Special:UploadAvatar")
                        entry("账户设置", "gearshape", "Special:Preferences")
                        Button(role: .destructive) { open("退出登录", "Special:UserLogout", kind: .logout) } label: { Label(t("退出登录"), systemImage: "rectangle.portrait.and.arrow.right") }
                    }
                } else {
                    Section {
                        Button { open("登录", "Special:UserLogin", kind: .login) } label: { Label(t("登录"), systemImage: "person.crop.circle") }.accessibilityIdentifier("account-login")
                        Button { open("注册账号", "Special:CreateAccount", kind: .register) } label: { Label(t("注册账号"), systemImage: "person.badge.plus") }.accessibilityIdentifier("account-register")
                    }
                    Text(t("使用天一维基账号，注册与登录遵循本站网页流程。"))
                }
            }
        }
        .task { await session.refresh(site) }
        .sheet(item: $flow) { request in TianyiWebFlow(request: request, site: site, session: session).id(request.id) }
    }
    private func entry(_ key: String, _ icon: String, _ title: String) -> some View {
        Button { open(key, title) } label: { Label(t(key), systemImage: icon) }
    }
    private func open(_ key: String, _ title: String, kind: TianyiWebRequest.Kind = .page) {
        var parts = URLComponents(url: site.pageURL(title), resolvingAgainstBaseURL: false)!
        parts.queryItems?.append(URLQueryItem(name: "uselang", value: TianyiL10n.language == "zh" ? "zh-hans" : TianyiL10n.language))
        flow = TianyiWebRequest(url: parts.url!, title: t(key), kind: kind)
    }
}

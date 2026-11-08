import Foundation
import WMFData

@MainActor enum TianyiL10n {
    static let defaultLanguage: String = {
        let preferred = Locale.preferredLanguages.first?.split(separator: "-").first.map(String.init) ?? "zh"
        return WMFTianyiSite(rawValue: preferred)?.rawValue ?? "zh"
    }()
    private static let strings: [String: [String: String]] = {
        guard let url = Bundle.main.url(forResource: "Localizations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let table = try? JSONDecoder().decode([String: [String: String]].self, from: data) else { return [:] }
        return table
    }()
    static var language: String { UserDefaults.standard.string(forKey: "tianyiInterface") ?? defaultLanguage }
    static func text(_ key: String, language selectedLanguage: String? = nil) -> String { strings[selectedLanguage ?? language]?[key] ?? strings["zh"]?[key] ?? key }
}
@MainActor func t(_ key: String) -> String { TianyiL10n.text(key) }

@MainActor func tianyiErrorDescription(_ error: Error) -> String {
    let summary = t("加载失败，请检查网络后重试。")
    if let error = error as? WMFTianyiError {
        switch error {
        case .invalidResponse: return summary
        case .missingPage: return t("此语言站点暂无此词条。")
        case .api(let detail): return summary + "\n" + detail
        }
    }
    return summary + "\n" + error.localizedDescription
}

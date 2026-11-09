import Foundation

/// Metadata exposed by Tianyi's own MediaWiki pages; no authentication secrets.
public enum WMFTianyiAccountMetadata {
    public static func isWikiCookieDomain(_ value: String) -> Bool {
        let domain = value.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return domain == "tyzx.org" || domain == "wiki.tyzx.org" || WMFTianyiSite.allCases.contains { $0.host == domain }
    }

    public static func avatarURL(in html: String, site: WMFTianyiSite) -> URL? {
        guard let regex = try? NSRegularExpression(pattern: #""wgTyzxAvatarUrl"\s*:\s*("(?:\\.|[^"\\])*")"#),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html),
              let value = try? JSONDecoder().decode(String.self, from: Data(html[range].utf8)),
              let url = URL(string: value, relativeTo: site.baseURL)?.absoluteURL,
              WMFTianyiSite.matching(url) == site,
              !url.path.hasSuffix("default-avatar.svg") else { return nil }
        return url
    }

    public static func cacheScope(site: WMFTianyiSite, userID: Int?, credentialFingerprint: String?) -> String {
        if let userID, userID > 0 { return "\(site.rawValue)-user-\(userID)" }
        if let fingerprint = credentialFingerprint {
            // Only an already-hashed fingerprint is accepted in a file-system component.
            let safe = fingerprint.filter { "0123456789abcdef".contains($0) }
            return "pending-" + site.rawValue + "-" + safe.prefix(20)
        }
        return "anonymous"
    }
}

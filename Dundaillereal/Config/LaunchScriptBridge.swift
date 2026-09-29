import Foundation

enum LaunchScriptBridge {
    static let openSafari = "openSafari"
    static let open = "open"
    static let messageNames = [openSafari, open]

    static func externalURL(messageName: String, body: Any) -> URL? {
        guard messageNames.contains(messageName) else { return nil }
        if let value = body as? String { return normalizedURL(value) }
        guard let payload = body as? [String: Any] else { return nil }
        for key in ["url", "href", "link", "target"] {
            if let value = payload[key] as? String, let url = normalizedURL(value) {
                return url
            }
        }
        return nil
    }

    private static func normalizedURL(_ rawValue: String) -> URL? {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty,
              value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else { return nil }
        if URL(string: value)?.scheme != nil {
            // Do not turn unsupported schemes into HTTPS URLs.
            return LaunchConfiguration.webURL(value)
        }
        if value.hasPrefix("//") {
            return LaunchConfiguration.webURL("https:\(value)")
        }
        guard !value.hasPrefix("/"),
              let url = LaunchConfiguration.webURL("https://\(value)"),
              url.host?.contains(".") == true else { return nil }
        return url
    }
}

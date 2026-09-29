import Foundation

@main struct ScriptBridgeTests {
    static func main() {
        for name in ["openSafari", "open"] {
            for value in ["https://example.com/path?q=1#section", "http://example.com/path"] {
                precondition(LaunchScriptBridge.externalURL(messageName: name, body: value)?.absoluteString == value)
            }
            for value in ["  https://example.com/path\n", "//example.com/path", "example.com/path"] {
                precondition(LaunchScriptBridge.externalURL(messageName: name, body: value)?.absoluteString == "https://example.com/path")
            }
            for key in ["url", "href", "link", "target"] {
                precondition(LaunchScriptBridge.externalURL(messageName: name, body: [key: "https://example.com"])?.host == "example.com")
            }
            let candidates = ["url": "javascript:alert(1)", "href": "https://example.com"]
            precondition(LaunchScriptBridge.externalURL(messageName: name, body: candidates)?.host == "example.com")
            for body: Any in ["", "  ", "/path.html", "javascript:alert(1)", "javascript:example.com",
                              "file:///tmp/page.html", "mailto:user@example.com", "custom://example.com",
                              "https://user:password@example.com", "example .com", "https://",
                              123, NSNull(), ["https://example.com"], ["url": 123], ["unknown": "https://example.com"]] {
                precondition(LaunchScriptBridge.externalURL(messageName: name, body: body) == nil, "Unexpected URL for \(body)")
            }
        }
        precondition(LaunchScriptBridge.externalURL(messageName: "unknown", body: "https://example.com") == nil)
        print("PASS both bridge names, all payload keys, URL normalization and invalid input rejection")
    }
}

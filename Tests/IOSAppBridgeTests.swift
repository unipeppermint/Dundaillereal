import Foundation
import JavaScriptCore

@main struct IOSAppBridgeTests {
    static func main() {
        let context = JSContext()!
        context.evaluateScript("var window = {webkit: {messageHandlers: {iosapp: {postMessage: function(body) { window.received = body; }}}}};")
        context.evaluateScript(IOSAppBridge.script)
        for expression in [
            "window.iosapp.postMessage('purchased', {value:99.9,currency:'USD'})",
            "window.iosapp.postMessage('purchased', JSON.stringify({value:99.9,currency:'USD'}))"
        ] {
            context.evaluateScript(expression)
            precondition(context.exception == nil)
            let body = context.evaluateScript("window.received")!.toDictionary()!
            precondition(IOSAppBridge.decode(body) == .event(.init(name: .purchased, value: 99.9, currency: "USD")))
        }
        print("PASS injected two-argument JavaScript bridge handles object and JSON string payloads")

        for action in ["purchased", "addtocart", "addtowishlist", "completeregistration"] {
            let body: [String: Any] = ["action": action, "params": ["value": 10, "currency": " usd "]]
            precondition(IOSAppBridge.decode(body) == .event(.init(name: .init(rawValue: action)!, value: 10, currency: "USD")))
        }
        precondition(IOSAppBridge.decode(["action": "completeregistration", "params": [:]]) == .event(.init(name: .completeregistration, value: nil, currency: nil)))
        print("PASS four documented events, integer amounts, currency normalization and amount-free registration")

        for params: Any in [["url": "https://example.com/pay"], #"{"url":"https://example.com/pay","uid":123,"email":"person@example.com"}"#] {
            precondition(IOSAppBridge.decode(["action": "openWindow", "params": params]) == .openWindow(URL(string: "https://example.com/pay")!))
        }
        let extraFields: [String: Any] = ["action": "purchased", "params": ["value": 5, "currency": "USD", "email": "person@example.com", "phone": "123"]]
        precondition(IOSAppBridge.decode(extraFields) == .event(.init(name: .purchased, value: 5, currency: "USD")))
        print("PASS external link parsing and event payload allowlist excludes personal data")

        let invalid: [Any] = [
            [:], ["action": "unknown", "params": [:]],
            ["action": "purchased", "params": "invalid json"],
            ["action": "purchased", "params": #"[1,2]"#],
            ["action": "purchased", "params": ["value": true, "currency": "USD"]],
            ["action": "purchased", "params": ["value": "9.9", "currency": "USD"]],
            ["action": "purchased", "params": ["value": -1, "currency": "USD"]],
            ["action": "purchased", "params": ["value": Double.infinity, "currency": "USD"]],
            ["action": "purchased", "params": ["value": Double.nan, "currency": "USD"]],
            ["action": "purchased", "params": ["value": 1, "currency": "ZZZ"]],
            ["action": "purchased", "params": [:]],
            ["action": "completeregistration", "params": ["value": 1]],
            ["action": "openWindow", "params": ["url": "javascript:alert(1)"]],
            ["action": "openWindow", "params": ["url": "file:///tmp/page.html"]],
            ["action": "openWindow", "params": ["url": "https://user:password@example.com"]]
        ]
        for body in invalid { precondition(IOSAppBridge.decode(body) == nil, "Must reject \(body)") }
        print("PASS malformed messages, invalid monetary fields and unsafe URL schemes rejected")
    }
}

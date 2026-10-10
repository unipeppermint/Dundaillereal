import Foundation
import JavaScriptCore

@main struct IOSAppBridgeTests {
    static func main() {
        let context = JSContext()!
        context.evaluateScript("var window = {webkit: {messageHandlers: {iosapp: {postMessage: function(body) { window.received = body; }}}}};")
        context.evaluateScript(IOSAppBridge.script)
        for expression in [
            "window.iosapp.postMessage('openWindow', {url:'https://example.com/help'})",
            "window.iosapp.postMessage('openWindow', JSON.stringify({url:'https://example.com/help'}))"
        ] {
            context.evaluateScript(expression)
            precondition(context.exception == nil)
            let body = context.evaluateScript("window.received")!.toDictionary()!
            precondition(IOSAppBridge.decode(body) == .openWindow(URL(string: "https://example.com/help")!))
        }
        print("PASS external links still work with object and JSON string payloads")

        for action in ["purchased", "addtocart", "addtowishlist", "completeregistration"] {
            for params in ["{value:99.9,currency:'USD'}", "JSON.stringify({value:99.9,currency:'USD'})", "{}"] {
                context.evaluateScript("window.iosapp.postMessage('\(action)', \(params))")
                precondition(context.exception == nil)
                let body = context.evaluateScript("window.received")!.toDictionary()!
                precondition(IOSAppBridge.decode(body) == nil, "Removed webpage events must be rejected")
            }
        }
        print("PASS all four commerce/registration actions are rejected through the actual JavaScript bridge")

        let invalid: [Any] = [
            [:], ["action": "unknown", "params": [:]],
            ["action": "openWindow", "params": "invalid json"],
            ["action": "openWindow", "params": #"[1,2]"#],
            ["action": "openWindow", "params": ["url": "javascript:alert(1)"]],
            ["action": "openWindow", "params": ["url": "file:///tmp/page.html"]],
            ["action": "openWindow", "params": ["url": "https://user:password@example.com"]]
        ]
        for body in invalid { precondition(IOSAppBridge.decode(body) == nil) }
        print("PASS malformed and unsafe external links are rejected")
    }
}

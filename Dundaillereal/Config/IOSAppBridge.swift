import Foundation

/// The H5 protocol uses two arguments; WKScriptMessageHandler accepts one envelope.
enum IOSAppBridge {
    static let handlerName = "iosapp"
    static let script = """
    (function () {
      window.iosapp = {
        postMessage: function (action, params) {
          window.webkit.messageHandlers.iosapp.postMessage({
            action: action, params: params == null ? {} : params
          });
        }
      };
    })();
    """

    enum Command: Equatable {
        case openWindow(URL)
    }

    static func decode(_ body: Any) -> Command? {
        guard let envelope = body as? [String: Any],
              let action = envelope["action"] as? String,
              let params = parameters(envelope["params"]) else { return nil }
        if action == "openWindow" {
            guard let url = LaunchScriptBridge.externalURL(messageName: "open", body: params) else { return nil }
            return .openWindow(url)
        }
        // The privacy policy permits installation/activation measurement only.
        return nil
    }

    private static func parameters(_ raw: Any?) -> [String: Any]? {
        if let dictionary = raw as? [String: Any] { return dictionary }
        if raw == nil || raw is NSNull { return [:] }
        guard let string = raw as? String, string.utf8.count <= 65_536,
              let data = string.data(using: .utf8),
              let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return dictionary
    }
}

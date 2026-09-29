import Foundation
import CoreFoundation

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

    enum EventName: String {
        case purchased, addtocart, addtowishlist, completeregistration
    }

    struct Event: Equatable {
        let name: EventName
        let value: Double?
        let currency: String?
    }

    enum Command: Equatable {
        case openWindow(URL)
        case event(Event)
    }

    static func decode(_ body: Any) -> Command? {
        guard let envelope = body as? [String: Any],
              let action = envelope["action"] as? String,
              let params = parameters(envelope["params"]) else { return nil }
        if action == "openWindow" {
            guard let url = LaunchScriptBridge.externalURL(messageName: "open", body: params) else { return nil }
            return .openWindow(url)
        }
        guard let name = EventName(rawValue: action) else { return nil }
        // Registration can be reported without inventing an amount. If monetary
        // fields are supplied, validate the complete pair just like purchase events.
        if name == .completeregistration, params["value"] == nil, params["currency"] == nil {
            return .event(Event(name: name, value: nil, currency: nil))
        }
        guard let number = params["value"] as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(),
              number.doubleValue.isFinite, number.doubleValue >= 0,
              let rawCurrency = params["currency"] as? String else { return nil }
        let currency = rawCurrency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard Locale.isoCurrencyCodes.contains(currency) else { return nil }
        return .event(Event(name: name, value: number.doubleValue, currency: currency))
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

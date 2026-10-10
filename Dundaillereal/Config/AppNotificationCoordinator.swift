import Foundation
import UserNotifications

/// Routes system push callbacks separately from the on-device message inbox.
@MainActor
final class AppNotificationCoordinator: NSObject, UNUserNotificationCenterDelegate {
    static let shared = AppNotificationCoordinator()
    var onRemoteNotification: (([AnyHashable: Any]) -> Void)?
    var onRemoteResponse: ((UNNotificationResponse) -> Void)?
    private let center = UNUserNotificationCenter.current()

    private override init() { super.init() }

    func configure() {
        center.delegate = self
        // Remove the earlier notification preview when upgrading to the inbox version.
        let legacyPreview = ["rollweave.local.preview"]
        center.removePendingNotificationRequests(withIdentifiers: legacyPreview)
        center.removeDeliveredNotifications(withIdentifiers: legacyPreview)
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                           willPresent notification: UNNotification,
                                           withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard notification.request.trigger is UNPushNotificationTrigger else {
            completionHandler([])
            return
        }
        completionHandler([.banner, .list, .sound, .badge])
        Task { @MainActor in self.onRemoteNotification?(notification.request.content.userInfo) }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                           didReceive response: UNNotificationResponse,
                                           withCompletionHandler completionHandler: @escaping () -> Void) {
        guard response.notification.request.trigger is UNPushNotificationTrigger else {
            completionHandler()
            return
        }
        Task { @MainActor in
            self.onRemoteResponse?(response)
            completionHandler()
        }
    }
}

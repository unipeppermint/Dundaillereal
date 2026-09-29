import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import OSLog

/// App-wide FCM lifecycle. All observable state and events are delivered on the main actor.
@MainActor
final class FirebasePushManager: NSObject {
    static let shared = FirebasePushManager()
    static let tokenDidChange = Notification.Name("Config.FCMTokenDidChange")
    static let notificationReceived = Notification.Name("Config.PushNotificationReceived")
    static let notificationOpened = Notification.Name("Config.PushNotificationOpened")

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Rollweave", category: "Push")
    private(set) var isConfigured = false
    private(set) var fcmToken: String?
    private(set) var lastOpenedNotification: [AnyHashable: Any]?
    private var lastOpenedResponseID: String?

    private override init() { super.init() }

    func configure(application: UIApplication) {
        guard !isConfigured else { return }
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else {
            logger.error("Firebase push disabled: GoogleService-Info.plist is missing or invalid.")
            return
        }
        if FirebaseApp.app() == nil { FirebaseApp.configure(options: options) }
        isConfigured = true
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        // APNs registration does not display the notification permission sheet.
        application.registerForRemoteNotifications()
    }

    func requestAuthorization(completion: @escaping () -> Void) {
        guard isConfigured else { completion(); return }
        let logger = self.logger
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, error in
            if let error {
                logger.error("Notification authorization failed: \(error.localizedDescription, privacy: .public)")
            }
            Task { @MainActor in
                completion()
            }
        }
    }

    func registeredForRemoteNotifications(deviceToken: Data) {
        guard isConfigured else { return }
        // Production APNs only, matching PushNotifications.entitlements.
        Messaging.messaging().setAPNSToken(deviceToken, type: .prod)
    }

    func failedToRegisterForRemoteNotifications(_ error: Error) {
        logger.error("APNs registration failed: \(error.localizedDescription, privacy: .public)")
    }

    private func updateToken(_ token: String?) {
        guard let token, !token.isEmpty, token != fcmToken else { return }
        fcmToken = token
        NotificationCenter.default.post(name: Self.tokenDidChange, object: self, userInfo: ["token": token])
    }

    func receivedNotification(_ userInfo: [AnyHashable: Any]) {
        guard isConfigured else { return }
        Messaging.messaging().appDidReceiveMessage(userInfo)
        NotificationCenter.default.post(name: Self.notificationReceived, object: self, userInfo: userInfo)
    }

    func openedNotification(_ response: UNNotificationResponse) {
        guard isConfigured, response.actionIdentifier != UNNotificationDismissActionIdentifier else { return }
        let responseID = response.notification.request.identifier + ":" + response.actionIdentifier
        // Scene connection and the notification delegate may report the same cold-start tap.
        guard lastOpenedResponseID != responseID else { return }
        lastOpenedResponseID = responseID
        let payload = response.notification.request.content.userInfo
        lastOpenedNotification = payload
        Messaging.messaging().appDidReceiveMessage(payload)
        NotificationCenter.default.post(name: Self.notificationOpened, object: self, userInfo: payload)
    }
}

extension FirebasePushManager: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task { @MainActor [weak self] in self?.updateToken(fcmToken) }
    }
}

extension FirebasePushManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                           willPresent notification: UNNotification,
                                           withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound, .badge])
        Task { @MainActor [weak self] in self?.receivedNotification(notification.request.content.userInfo) }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                           didReceive response: UNNotificationResponse,
                                           withCompletionHandler completionHandler: @escaping () -> Void) {
        Task { @MainActor [weak self] in
            self?.openedNotification(response)
            completionHandler()
        }
    }
}

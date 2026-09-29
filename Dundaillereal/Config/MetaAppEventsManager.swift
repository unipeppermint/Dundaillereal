import UIKit
import AppTrackingTransparency
import FBSDKCoreKit
import OSLog

@MainActor
final class MetaAppEventsManager {
    static let shared = MetaAppEventsManager()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Rollweave", category: "MetaEvents")
    private var configured = false
    private var pendingEvents: [IOSAppBridge.Event] = []
    private var activationPending = false

    private init() {}

    func configure(application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        guard !configured else { return }
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        configured = true
        // Manual lifecycle/events avoid automatic purchase logging alongside H5 events.
        Settings.shared.isAutoLogAppEventsEnabled = false
        Settings.shared.isSKAdNetworkReportEnabled = true
        synchronizeTrackingSettings()
    }

    func sceneDidBecomeActive() {
        activationPending = true
        TrackingAuthorizationCoordinator.shared.applicationDidBecomeActive()
    }

    func updateTrackingAuthorization() {
        guard configured else { return }
        finishAuthorization()
    }

    private func synchronizeTrackingSettings() {
        let authorized = ATTrackingManager.trackingAuthorizationStatus == .authorized
        Settings.shared.isAdvertiserIDCollectionEnabled = authorized
        // Meta 17+ reads ATT directly on iOS 17+. Earlier OS versions require this flag.
        if #available(iOS 17.0, *) {} else {
            Settings.shared.isAdvertiserTrackingEnabled = authorized
        }
    }

    private func finishAuthorization() {
        synchronizeTrackingSettings()
        guard ATTrackingManager.trackingAuthorizationStatus != .notDetermined else { return }
        if activationPending {
            activationPending = false
            AppEvents.shared.activateApp()
        }
        let events = pendingEvents
        pendingEvents.removeAll()
        for event in events { send(event) }
    }

    func log(_ event: IOSAppBridge.Event) {
        guard configured else { return }
        synchronizeTrackingSettings()
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            guard pendingEvents.count < 100 else {
                logger.error("Meta event queue is full while waiting for tracking authorization.")
                return
            }
            pendingEvents.append(event)
            TrackingAuthorizationCoordinator.shared.applicationDidBecomeActive()
        } else {
            send(event)
        }
    }

    private func send(_ event: IOSAppBridge.Event) {
        let parameters: [AppEvents.ParameterName: Any] = event.currency.map { [.currency: $0] } ?? [:]
        switch event.name {
        case .purchased:
            if let value = event.value, let currency = event.currency {
                AppEvents.shared.logPurchase(amount: value, currency: currency)
            }
        case .addtocart:
            if let value = event.value {
                AppEvents.shared.logEvent(.addedToCart, valueToSum: value, parameters: parameters)
            }
        case .addtowishlist:
            if let value = event.value {
                AppEvents.shared.logEvent(.addedToWishlist, valueToSum: value, parameters: parameters)
            }
        case .completeregistration:
            if let value = event.value {
                AppEvents.shared.logEvent(.completedRegistration, valueToSum: value, parameters: parameters)
            } else {
                AppEvents.shared.logEvent(.completedRegistration)
            }
        }
        // SDK acceptance is not proof of server delivery; verify in Meta Events Manager.
        logger.info("Queued Meta event: \(event.name.rawValue, privacy: .public)")
    }

    func open(_ url: URL, sourceApplication: String? = nil, annotation: Any? = nil) -> Bool {
        ApplicationDelegate.shared.application(UIApplication.shared, open: url,
                                               sourceApplication: sourceApplication, annotation: annotation)
    }
}

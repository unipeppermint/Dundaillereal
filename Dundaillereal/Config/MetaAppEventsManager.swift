import UIKit
import AppTrackingTransparency
import FBSDKCoreKit
import OSLog

@MainActor
final class MetaAppEventsManager {
    static let shared = MetaAppEventsManager()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Rollweave", category: "MetaEvents")
    private let client = MetaSDKActivationClient()
    private lazy var gate = MetaActivationGate(client: client)

    private init() {}

    /// Store launch context only. This must not touch the SDK before ATT is authorized.
    func configure(application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        client.launchOptions = launchOptions
    }

    func sceneDidBecomeActive() {
        updateTrackingAuthorization()
        TrackingAuthorizationCoordinator.shared.applicationDidBecomeActive()
    }

    func sceneWillResignActive() {
        try? gate.update(isActive: false, authorized: false)
    }

    func updateTrackingAuthorization() {
        do {
            try gate.update(isActive: UIApplication.shared.applicationState == .active,
                            authorized: ATTrackingManager.trackingAuthorizationStatus == .authorized)
        } catch {
            // Fail closed if the old SDK event cache cannot be removed.
            logger.error("Meta activation disabled: \(error.localizedDescription, privacy: .public)")
        }
    }

    func open(_ url: URL, sourceApplication: String? = nil, annotation: Any? = nil) -> Bool {
        guard gate.initialized,
              ATTrackingManager.trackingAuthorizationStatus == .authorized,
              UIApplication.shared.applicationState == .active else { return false }
        return ApplicationDelegate.shared.application(UIApplication.shared, open: url,
                                                       sourceApplication: sourceApplication, annotation: annotation)
    }
}

@MainActor
private final class MetaSDKActivationClient: MetaActivationClient {
    var launchOptions: [UIApplication.LaunchOptionsKey: Any]?

    func initialize() throws {
        let library = try FileManager.default.url(for: .libraryDirectory, in: .userDomainMask,
                                                   appropriateFor: nil, create: false)
        try MetaEventCache.removePersistedEvents(in: library)
        // Info.plist disables automatic logging and SKAdNetwork before initialization.
        ApplicationDelegate.shared.application(UIApplication.shared, didFinishLaunchingWithOptions: launchOptions)
        launchOptions = nil
        AppEvents.shared.flushBehavior = .explicitOnly
        Settings.shared.isAutoLogAppEventsEnabled = false
        Settings.shared.isSKAdNetworkReportEnabled = false
    }

    func setCollectionEnabled(_ enabled: Bool) {
        let authorized = enabled && ATTrackingManager.trackingAuthorizationStatus == .authorized
        AppEvents.shared.flushBehavior = .explicitOnly
        Settings.shared.isAutoLogAppEventsEnabled = false
        Settings.shared.isSKAdNetworkReportEnabled = false
        Settings.shared.isAdvertiserIDCollectionEnabled = authorized
        if #available(iOS 17.0, *) {} else {
            Settings.shared.isAdvertiserTrackingEnabled = authorized
        }
    }

    func activate() {
        guard UIApplication.shared.applicationState == .active,
              ATTrackingManager.trackingAuthorizationStatus == .authorized else { return }
        // SDK handles installation attribution and app activation; no webpage events are accepted.
        AppEvents.shared.activateApp()
        guard ATTrackingManager.trackingAuthorizationStatus == .authorized else { return }
        AppEvents.shared.flush()
    }
}

import UIKit
import AppTrackingTransparency

/// Requests ATT before notifications, after the active scene has settled.
@MainActor
final class TrackingAuthorizationCoordinator {
    static let shared = TrackingAuthorizationCoordinator()
    private var scheduled = false
    private var requestInFlight = false
    private var trackingAttempted = false
    private var notificationsRequested = false

    private init() {}

    func applicationDidBecomeActive() {
        guard !scheduled, !requestInFlight else { return }
        scheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            self.scheduled = false
            self.advance()
        }
    }

    private func advance() {
        guard UIApplication.shared.applicationState == .active, !requestInFlight else { return }
        MetaAppEventsManager.shared.updateTrackingAuthorization()
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined && !trackingAttempted {
            trackingAttempted = true
            requestInFlight = true
            ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.requestInFlight = false
                    MetaAppEventsManager.shared.updateTrackingAuthorization()
                    // Request push permission after ATT finishes, even when ATT is declined.
                    self.applicationDidBecomeActive()
                }
            }
        } else if !notificationsRequested {
            notificationsRequested = true
            requestInFlight = true
            FirebasePushManager.shared.requestAuthorization { [weak self] in
                self?.requestInFlight = false
            }
        }
    }
}

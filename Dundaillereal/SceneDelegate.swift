import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene, willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene)
        let incomingURL = connectionOptions.urlContexts.first
        let handledByMeta = incomingURL.map {
            MetaAppEventsManager.shared.open($0.url, sourceApplication: $0.options.sourceApplication,
                                             annotation: $0.options.annotation)
        } ?? false
        let root = LaunchController(documentURL: handledByMeta ? nil : incomingURL?.url)
        window.rootViewController = root
        window.overrideUserInterfaceStyle = .light
        self.window = window
        window.makeKeyAndVisible()
        if let response = connectionOptions.notificationResponse {
            FirebasePushManager.shared.openedNotification(response)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let context = URLContexts.first,
           !MetaAppEventsManager.shared.open(context.url, sourceApplication: context.options.sourceApplication,
                                            annotation: context.options.annotation) {
            (window?.rootViewController as? LaunchController)?.receive(context.url)
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        MetaAppEventsManager.shared.sceneDidBecomeActive()
    }
}

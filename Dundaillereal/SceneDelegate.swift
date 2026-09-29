import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene, willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene)
        let root = LaunchController(documentURL: connectionOptions.urlContexts.first?.url)
        window.rootViewController = root
        window.overrideUserInterfaceStyle = .light
        self.window = window
        window.makeKeyAndVisible()
        if let response = connectionOptions.notificationResponse {
            FirebasePushManager.shared.openedNotification(response)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            (window?.rootViewController as? LaunchController)?.receive(url)
        }
    }
}

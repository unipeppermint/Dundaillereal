import UIKit

/// Owns startup routing while keeping the existing native app and document import flow.
final class LaunchController: UIViewController {
    private let service = LaunchLinkService()
    private let cache = LaunchLinkCache()
    private var requestTask: Task<Void, Never>?
    private var content: UIViewController?
    private var started = false
    private var pendingDocumentURL: URL?

    init(documentURL: URL? = nil) {
        pendingDocumentURL = documentURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        show(UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()!)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !started else { return }
        started = true
        requestTask = Task { [weak self, service, cachedURL = cache.url] in
            let launchURL = await service.startupURL(cachedURL: cachedURL)
            guard !Task.isCancelled, let self else { return }
            self.requestTask = nil
            if self.pendingDocumentURL != nil {
                self.showNativeApp()
            } else if let url = launchURL {
                let browser = LaunchWebViewController(url: url, cache: self.cache)
                browser.onOpenNativeApp = { [weak self] in self?.showNativeApp() }
                self.show(browser)
            } else {
                self.showNativeApp()
            }
        }
    }

    func receive(_ url: URL) {
        pendingDocumentURL = url
        // A document explicitly opened by the user should still reach the native importer.
        guard started else { return }
        requestTask?.cancel()
        requestTask = nil
        showNativeApp()
    }

    private func showNativeApp() {
        let root: RootController
        if let existing = content as? RootController {
            root = existing
        } else {
            root = RootController()
            show(root)
        }
        if let url = pendingDocumentURL {
            pendingDocumentURL = nil
            DispatchQueue.main.async { root.receive(url) }
        }
    }

    private func show(_ controller: UIViewController) {
        content?.willMove(toParent: nil)
        content?.view.removeFromSuperview()
        content?.removeFromParent()
        addChild(controller)
        controller.view.frame = view.bounds
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(controller.view)
        controller.didMove(toParent: self)
        content = controller
        setNeedsStatusBarAppearanceUpdate()
    }

    override var childForStatusBarStyle: UIViewController? { content }
    override var childForStatusBarHidden: UIViewController? { content }

    deinit { requestTask?.cancel() }
}

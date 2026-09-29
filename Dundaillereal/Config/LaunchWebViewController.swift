import UIKit
import WebKit

final class LaunchWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    var onOpenNativeApp: (() -> Void)?
    private let initialURL: URL
    private let cache: LaunchLinkCache
    private let userContentController = WKUserContentController()
    private lazy var webView: WKWebView = {
        let handler = WeakLaunchScriptMessageHandler(target: self)
        LaunchScriptBridge.messageNames.forEach { userContentController.add(handler, name: $0) }
        userContentController.add(handler, name: IOSAppBridge.handlerName)
        userContentController.addUserScript(WKUserScript(source: IOSAppBridge.script,
                                                         injectionTime: .atDocumentStart,
                                                         forMainFrameOnly: true))

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.websiteDataStore = .default()
        return WKWebView(frame: .zero, configuration: configuration)
    }()
    private var launchCover: UIViewController?
    private var showingError = false

    init(url: URL, cache: LaunchLinkCache) {
        initialURL = url
        self.cache = cache
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        userContentController.removeScriptMessageHandler(forName: "openSafari")
        userContentController.removeScriptMessageHandler(forName: "open")
        userContentController.removeScriptMessageHandler(forName: "iosapp")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        let cover = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()!
        addChild(cover)
        cover.view.frame = view.bounds
        cover.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(cover.view)
        cover.didMove(toParent: self)
        launchCover = cover
        load(initialURL)
    }

    private func load(_ url: URL) {
        webView.load(URLRequest(url: url, timeoutInterval: 20))
    }

    private func removeCover() {
        launchCover?.willMove(toParent: nil)
        launchCover?.view.removeFromSuperview()
        launchCover?.removeFromParent()
        launchCover = nil
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        removeCover()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        removeCover()
        if let url = webView.url { cache.save(url) }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard LaunchConfiguration.webURL(navigationAction.request.url?.absoluteString) != nil else {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.isForMainFrame,
           let response = navigationResponse.response as? HTTPURLResponse,
           response.statusCode >= 400 {
            decisionHandler(.cancel)
            showLoadError()
            return
        }
        decisionHandler(.allow)
    }

    // Keep target="_blank" links in the same browser.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil,
           let url = LaunchConfiguration.webURL(navigationAction.request.url?.absoluteString) {
            load(url)
        }
        return nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { showLoadError() }

    private func handle(_ error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        showLoadError()
    }

    private func showLoadError() {
        guard !showingError else { return }
        showingError = true
        let alert = UIAlertController(title: "Unable to Open Page",
                                      message: "Please check your connection and try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            guard let self else { return }
            self.showingError = false
            self.load(self.webView.url ?? self.initialURL)
        })
        alert.addAction(UIAlertAction(title: "Open Rollweave", style: .cancel) { [weak self] _ in
            self?.showingError = false
            self?.onOpenNativeApp?()
        })
        present(alert, animated: true)
    }
}

extension LaunchWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.webView === webView else { return }
        if message.name == IOSAppBridge.handlerName {
            guard message.frameInfo.isMainFrame,
                  ["https", "http"].contains(message.frameInfo.securityOrigin.protocol),
                  let command = IOSAppBridge.decode(message.body) else { return }
            switch command {
            case .openWindow(let url): UIApplication.shared.open(url)
            case .event(let event): MetaAppEventsManager.shared.log(event)
            }
        } else if let url = LaunchScriptBridge.externalURL(messageName: message.name, body: message.body) {
            UIApplication.shared.open(url)
        }
    }
}

private final class WeakLaunchScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var target: (any WKScriptMessageHandler)?

    init(target: any WKScriptMessageHandler) { self.target = target }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}

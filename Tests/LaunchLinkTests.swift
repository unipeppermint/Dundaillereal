import Foundation

final class LaunchStub: URLProtocol {
    static var body = ""
    static var status = 200
    static var error: URLError?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        precondition(request.url == LaunchConfiguration.endpoint)
        precondition(request.httpMethod == "POST")
        precondition(request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded; charset=utf-8")
        var body = request.httpBody
        if body == nil, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var bytes = [UInt8](repeating: 0, count: 1024)
            var received = Data()
            while stream.hasBytesAvailable {
                let count = stream.read(&bytes, maxLength: bytes.count)
                guard count > 0 else { break }
                received.append(contentsOf: bytes.prefix(count))
            }
            body = received
        }
        precondition(body.flatMap { String(data: $0, encoding: .utf8) } == "username=com.benll.lyjmkn")
        if let error = Self.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status,
                                       httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(Self.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@main struct LaunchLinkTests {
    @MainActor static func main() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [LaunchStub.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let service = LaunchLinkService(session: session)
        let previous = URL(string: "https://previous.example/last-page")!
        let success = #"{"code":1,"data":{"path":"https://hx777go.com","show":1,"useAF":0},"message":"request was successful"}"#
        LaunchStub.body = success
        let fresh = await service.startupURL(cachedURL: previous)
        precondition(fresh?.absoluteString == "https://hx777go.com", "Fresh URL must supersede cache")
        print("PASS successful POST uses code=1/data.path and supersedes cache")

        for body in [
            #"{"code":-1,"data":{},"message":"user does not exist"}"#,
            #"{"code":1,"data":{}}"#,
            #"{"code":1,"data":{"path":""}}"#,
            #"{"code":1,"data":{"path":"javascript:alert(1)"}}"#,
            #"{"code":1,"data":{"path":"/relative"}}"#,
            #"{"code":1,"data":null}"#,
            "invalid json"
        ] {
            LaunchStub.body = body
            let fallback = await service.startupURL(cachedURL: previous)
            let native = await service.startupURL(cachedURL: nil)
            precondition(fallback == previous && native == nil)
        }
        print("PASS business failure, missing/invalid links and malformed JSON use cache or native app")
        LaunchStub.body = success
        LaunchStub.status = 503
        let httpFallback = await service.startupURL(cachedURL: previous)
        precondition(httpFallback == previous)
        LaunchStub.status = 200
        for failure in [URLError.timedOut, .notConnectedToInternet, .cancelled] {
            LaunchStub.error = URLError(failure)
            let fallback = await service.startupURL(cachedURL: previous)
            let native = await service.startupURL(cachedURL: nil)
            precondition(fallback == previous && native == nil)
        }
        print("PASS HTTP errors, timeout, offline and cancellation fallback")

        let suite = "LaunchLinkTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let cache = LaunchLinkCache(defaults: defaults)
        precondition(cache.url == nil)
        cache.save(previous)
        let relaunchedCache = LaunchLinkCache(defaults: UserDefaults(suiteName: suite)!)
        precondition(relaunchedCache.url == previous)
        cache.save(URL(string: "file:///invalid")!)
        precondition(cache.url == previous)
        let redirected = URL(string: "https://redirect.example/current")!
        cache.save(redirected)
        precondition(relaunchedCache.url == redirected)
        print("PASS persisted URL survives cache recreation; current URL replaces it; invalid URL preserves it")
    }
}

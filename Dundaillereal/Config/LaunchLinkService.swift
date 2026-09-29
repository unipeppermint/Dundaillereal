import Foundation

enum LaunchConfiguration {
    static let endpoint = URL(string: "https://ketwtyajxw.top/v2/api/user/login")!
    static let username = "com.benll.lyjmkn"

    static func webURL(_ value: String?) -> URL? {
        guard let value, let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(), ["https", "http"].contains(scheme),
              let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil else { return nil }
        return url
    }
}

final class LaunchLinkCache {
    private let defaults: UserDefaults
    private let key = "Config.lastVisitedLaunchURL"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var url: URL? { LaunchConfiguration.webURL(defaults.string(forKey: key)) }

    // Only called after WebKit successfully finishes a main-frame navigation.
    func save(_ url: URL) {
        guard let url = LaunchConfiguration.webURL(url.absoluteString) else { return }
        defaults.set(url.absoluteString, forKey: key)
    }
}

struct LaunchLinkService {
    enum Failure: Error { case invalidResponse, rejected, missingURL }

    let session: URLSession

    init(session: URLSession? = nil) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 20
        self.session = session ?? URLSession(configuration: configuration)
    }

    func startupURL(cachedURL: URL?) async -> URL? {
        do { return try await fetchURL() }
        catch { return cachedURL }
    }

    func fetchURL() async throws -> URL {
        var request = URLRequest(url: LaunchConfiguration.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        var form = URLComponents()
        form.queryItems = [URLQueryItem(name: "username", value: LaunchConfiguration.username)]
        request.httpBody = form.percentEncodedQuery?.data(using: .utf8)
        try Task.checkCancellation()
        // URLSession.data(for:) requires iOS 15. Bridge the callback API for iOS 14.
        let (data, response): (Data, URLResponse) = try await withCheckedThrowingContinuation { continuation in
            session.dataTask(with: request) { data, response, error in
                if let error { continuation.resume(throwing: error) }
                else if let data, let response { continuation.resume(returning: (data, response)) }
                else { continuation.resume(throwing: URLError(.badServerResponse)) }
            }.resume()
        }
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse,
              (200..<300).contains(response.statusCode) else { throw Failure.invalidResponse }
        return try Self.decodeURL(data)
    }

    static func decodeURL(_ data: Data) throws -> URL {
        struct Response: Decodable {
            let code: Int
            let data: Payload?
            struct Payload: Decodable { let path: String? }
        }
        let response = try JSONDecoder().decode(Response.self, from: data)
        guard response.code == 1 else { throw Failure.rejected }
        guard let url = LaunchConfiguration.webURL(response.data?.path) else { throw Failure.missingURL }
        return url
    }
}

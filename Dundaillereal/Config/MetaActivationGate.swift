import Foundation

@MainActor
protocol MetaActivationClient: AnyObject {
    func initialize() throws
    func setCollectionEnabled(_ enabled: Bool)
    func activate()
}

/// Only an active, explicitly authorized session may initialize or report to Meta.
@MainActor
final class MetaActivationGate {
    private let client: MetaActivationClient
    private(set) var initialized = false
    private var eligible = false

    init(client: MetaActivationClient) { self.client = client }

    func update(isActive: Bool, authorized: Bool) throws {
        guard isActive && authorized else {
            if initialized { client.setCollectionEnabled(false) }
            eligible = false
            return
        }
        guard !eligible else { return }
        if !initialized {
            try client.initialize()
            initialized = true
        }
        client.setCollectionEnabled(true)
        client.activate()
        eligible = true
    }
}

enum MetaEventCache {
    // SDK 18.0.3 uses these exact Library files (FBSDKAppEventsStateManager/TimeSpentData).
    // Purge before initialization so an upgrade cannot replay removed commerce events.
    static func removePersistedEvents(in library: URL, fileManager: FileManager = .default) throws {
        for filename in ["com-facebook-sdk-AppEventsPersistedEvents.json",
                         "com-facebook-sdk-AppEventsTimeSpent.json"] {
            let url = library.appendingPathComponent(filename)
            do { try fileManager.removeItem(at: url) }
            catch let error as CocoaError where error.code == .fileNoSuchFile { continue }
        }
    }
}

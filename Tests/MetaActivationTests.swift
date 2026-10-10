import Foundation

@MainActor
private final class Recorder: MetaActivationClient {
    var calls: [String] = []
    var failInitialization = false
    func initialize() throws {
        calls.append("initialize")
        if failInitialization { throw CocoaError(.fileReadNoPermission) }
    }
    func setCollectionEnabled(_ enabled: Bool) { calls.append(enabled ? "enable" : "disable") }
    func activate() { calls.append("activate") }
}

@main struct MetaActivationTests {
    @MainActor static func main() throws {
        let client = Recorder()
        let gate = MetaActivationGate(client: client)
        // .notDetermined, .denied, .restricted and unknown ATT states all map to false.
        for _ in 0..<4 {
            try gate.update(isActive: true, authorized: false)
            try gate.update(isActive: false, authorized: false)
        }
        try gate.update(isActive: false, authorized: true)
        precondition(client.calls.isEmpty)
        print("PASS no SDK initialization or events without both active state and explicit consent")

        try gate.update(isActive: true, authorized: true)
        precondition(client.calls == ["initialize", "enable", "activate"])
        try gate.update(isActive: true, authorized: true)
        precondition(client.calls.count == 3)
        print("PASS consent enables one activation; repeated permission callbacks do not duplicate it")

        try gate.update(isActive: false, authorized: true)
        precondition(client.calls.last == "disable")
        try gate.update(isActive: true, authorized: false)
        let count = client.calls.filter { $0 == "activate" }.count
        for _ in 0..<5 { try gate.update(isActive: true, authorized: false) }
        precondition(client.calls.filter { $0 == "activate" }.count == count)
        try gate.update(isActive: true, authorized: true)
        precondition(client.calls.filter { $0 == "activate" }.count == count + 1)
        precondition(client.calls.filter { $0 == "initialize" }.count == 1)
        print("PASS background/revocation disables collection; renewed consent sends only the current activation")

        let failing = Recorder()
        failing.failInitialization = true
        let failingGate = MetaActivationGate(client: failing)
        do {
            try failingGate.update(isActive: true, authorized: true)
            preconditionFailure("Cache cleanup failure must stop initialization")
        } catch {}
        precondition(failing.calls == ["initialize"] && !failingGate.initialized)
        print("PASS initialization failures do not enable collection or send events")

        let fm = FileManager.default
        let folder = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: folder) }
        for name in ["com-facebook-sdk-AppEventsPersistedEvents.json", "com-facebook-sdk-AppEventsTimeSpent.json", "library.json"] {
            try Data("old data".utf8).write(to: folder.appendingPathComponent(name))
        }
        try MetaEventCache.removePersistedEvents(in: folder)
        let remaining = try fm.contentsOfDirectory(atPath: folder.path)
        precondition(remaining == ["library.json"])
        try MetaEventCache.removePersistedEvents(in: folder)
        print("PASS legacy Meta queues are removed idempotently without touching game data")
    }
}

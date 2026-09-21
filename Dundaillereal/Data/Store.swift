import Foundation

struct Library: Codable {
    var schemaVersion = 1
    var works: [Definition] = []
    var favorites: Set<UUID> = []
    var session: Session?
    var history: [Session] = []
    var personalBests: [String: Int] = [:]

    init() {}
    enum CodingKeys: String, CodingKey {
        case schemaVersion, works, favorites, session, history, personalBests
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decode(Int.self, forKey: .schemaVersion)
        works = try c.decode([Definition].self, forKey: .works)
        favorites = try c.decode(Set<UUID>.self, forKey: .favorites)
        session = try c.decodeIfPresent(Session.self, forKey: .session)
        history = try c.decode([Session].self, forKey: .history)
        personalBests = try c.decodeIfPresent([String: Int].self, forKey: .personalBests) ?? [:]
        for s in history where s.players.count == 1 {
            let key = Self.bestKey(s.definition)
            personalBests[key] = max(personalBests[key] ?? 0, s.players[0].score)
        }
    }

    static func bestKey(_ definition: Definition) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return definition.template.rawValue + ":"
            + ((try? encoder.encode(definition.rules).base64EncodedString()) ?? "")
    }

    mutating func normalizeEnglishLabels() {
        for index in works.indices { works[index].name = EnglishText.gameName(works[index]) }
        session?.normalizeEnglishLabels()
        for index in history.indices { history[index].normalizeEnglishLabels() }
    }

    func validate() throws {
        guard schemaVersion == 1 else { throw RuleError.invalid("This library version is not supported. Please update the app.") }
        guard works.count <= 1000, history.count <= 100, Set(works.map(\.id)).count == works.count
        else { throw RuleError.invalid("The library contains invalid data.") }
        for work in works { try work.validate() }
        try session?.validate()
        for record in history {
            try record.validate()
            guard record.phase == .finished else { throw RuleError.invalid("A history entry contains an unfinished game.") }
        }
    }
}
struct WorkFile: Codable {
    var schemaVersion = 1
    var definition: Definition

    static func decode(_ data: Data) throws -> Definition {
        guard data.count <= 1_048_576 else { throw RuleError.invalid("Game files must not exceed 1 MB.") }
        let file: WorkFile
        do { file = try JSONDecoder().decode(WorkFile.self, from: data) } catch {
            throw RuleError.invalid("Cannot read this game. Choose a valid .dicework file.")
        }
        guard file.schemaVersion == 1 else { throw RuleError.invalid("This file version is not supported. Please update the app.") }
        try file.definition.validate()
        var d = file.definition
        d.name = EnglishText.gameName(d)
        d.id = UUID()
        d.imported = true
        return d
    }
}
/// All disk access is serialized; commits publish in memory only after the atomic disk write succeeds.
final class Store {
    static let shared: Store = {
        #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if let index = args.firstIndex(of: "--ui-testing"), args.indices.contains(index + 1) {
                return Store(
                    directory: FileManager.default.temporaryDirectory.appendingPathComponent(
                        "UITests-" + args[index + 1]))
            }
        #endif
        return Store()
    }()
    private let queue = DispatchQueue(label: "dicework.storage")
    private let url: URL
    private(set) var library = Library()
    private(set) var warning: String?
    private(set) var blocked = false

    init(directory: URL? = nil) {
        let directory =
            directory
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DiceWorkshop")
        url = directory.appendingPathComponent("library.json")
        queue.sync {
            do {
                try FileManager.default.createDirectory(
                    at: directory, withIntermediateDirectories: true)
                if FileManager.default.fileExists(atPath: url.path) {
                    do { library = try read(url) } catch {
                        let corrupt = directory.appendingPathComponent(
                            "unreadable-\(UUID().uuidString).json")
                        try? FileManager.default.copyItem(at: url, to: corrupt)
                        if let backup = try? read(url.appendingPathExtension("backup")) {
                            library = backup
                            try JSONEncoder().encode(backup).write(to: url, options: .atomic)
                            warning = "Your data could not be read. The last valid backup was restored and the unreadable file was kept."
                        } else {
                            blocked = true
                            warning =
                                "The library could not be read. The original file was kept. Only rule playtests are available to avoid overwriting it. Try reloading in Settings."
                        }
                    }
                }
            } catch {
                blocked = true
                warning = "Cannot access the data folder. Please try again."
            }
        }
    }

    private func read(_ location: URL) throws -> Library {
        let data = try Data(contentsOf: location)
        var result = try JSONDecoder().decode(Library.self, from: data)
        try result.validate()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let before = try encoder.encode(result)
        result.normalizeEnglishLabels()
        try result.validate()
        let after = try encoder.encode(result)
        if before != after {
            let backup = location.appendingPathExtension("before-english")
            if !FileManager.default.fileExists(atPath: backup.path) {
                try data.write(to: backup, options: .atomic)
            }
            try after.write(to: location, options: .atomic)
        }
        return result
    }

    func reload() throws {
        let value = try queue.sync { try read(url) }
        library = value
        blocked = false
        warning = nil
    }

    func commit(_ change: (inout Library) throws -> Void) throws {
        guard !blocked else { throw RuleError.invalid(warning ?? "The library is currently read-only.") }
        var candidate = library
        try change(&candidate)
        candidate.normalizeEnglishLabels()
        try candidate.validate()
        let data = try JSONEncoder().encode(candidate)
        try queue.sync {
            if FileManager.default.fileExists(atPath: url.path) {
                let old = try JSONEncoder().encode(library)
                try old.write(to: url.appendingPathExtension("backup"), options: .atomic)
            }
            try data.write(to: url, options: .atomic)
        }
        library = candidate
    }

    func save(_ session: Session) throws {
        guard !session.trial else { return }
        try commit {
            $0.session = session.phase == .finished ? nil : session
            if session.phase == .finished, !$0.history.contains(where: { $0.id == session.id }) {
                if session.players.count == 1 {
                    let key = Library.bestKey(session.definition)
                    $0.personalBests[key] = max(
                        $0.personalBests[key] ?? 0, session.players[0].score)
                }
                $0.history.insert(session, at: 0)
                $0.history = Array($0.history.prefix(100))
            }
        }
    }

    func importFile(_ url: URL) throws -> Definition {
        let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile == true, let size = values.fileSize, size <= 1_048_576 else {
            throw RuleError.invalid("Choose a game file no larger than 1 MB.")
        }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: 1_048_577) ?? Data()
        return try WorkFile.decode(data)
    }
}

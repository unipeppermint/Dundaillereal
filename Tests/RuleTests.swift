import Foundation

@main struct RuleTests {
    static var count = 0

    static func check(_ condition: @autoclosure () -> Bool, _ name: String) {
        precondition(condition(), name)
        count += 1
        print("PASS \(name)")
    }

    static func rejects(_ name: String, _ operation: () throws -> Void) {
        do {
            try operation()
            fatalError("Expected rejection: \(name)")
        } catch {
            count += 1
            print("PASS \(name)")
        }
    }

    static func action(_ s: inout Session, _ action: Action, values: [Int] = [1]) throws {
        var i = 0
        try s.apply(action, revision: s.revision) {
            defer { i += 1 }
            return values[i % values.count]
        }
    }

    static func main() throws {
        for d in Definition.builtins { try d.validate() }
        var s = try Session(definition: Definition.builtins[0], names: ["甲", "乙"])
        try action(&s, .roll, values: [1, 2, 3])
        try action(&s, .toggle(0))
        try action(&s, .toggle(1))
        try action(&s, .toggle(2))
        try action(&s, .target(6))
        check(tryScore(s) == 3, "subset sum exact")
        let old = s.revision
        try action(&s, .confirm)
        check(
            s.players[0].score == 3 && s.players[0].stations[6] == 3,
            "exact scoring and station consumption")
        rejects("duplicate confirmation revision") { try s.apply(.confirm, revision: old) }
        try action(&s, .next)
        check(s.current == 1 && s.round == 1, "multiplayer rotation")
        try action(&s, .roll)
        try action(&s, .reroll(0))
        try action(&s, .reroll(0))
        rejects("reroll budget exhausted") { try action(&s, .reroll(0)) }
        check(s.players[0].rerolls == 2 && s.players[1].rerolls == 0, "independent reroll budgets")
        try action(&s, .toggle(0))
        try action(&s, .target(6))
        try action(&s, .confirm)
        check(s.player.stations[6] == 0, "zero still consumes station")
        var d = Definition.builtins[0]
        d.rules.targets = [3, 6, 9]
        d.rules.rounds = 3
        var streak = try Session(definition: d, names: ["甲"])
        for value in 1...3 {
            try action(&streak, .roll, values: [value])
            for i in 0..<3 { try action(&streak, .toggle(i)) }
            try action(&streak, .target(value * 3))
            try action(&streak, .confirm)
            try action(&streak, .next)
        }
        check(
            streak.phase == .finished && streak.player.score == 11 && streak.player.streak == 0,
            "streak bonus and final state")
        var near = try Session(definition: Definition.builtins[0], names: ["甲"])
        try action(&near, .roll, values: [5])
        try action(&near, .toggle(0))
        try action(&near, .target(6))
        check(tryScore(near) == 1, "near score")
        near.players[0].streak = 2
        try action(&near, .confirm)
        check(near.player.streak == 0, "non-exact resets streak")
        var lucky = try Session(definition: Definition.builtins[1], names: ["甲"])
        try action(&lucky, .roll, values: [4, 4, 4, 4, 6])
        check(tryScore(lucky) == 26, "lucky pairs counted disjointly")
        try action(&lucky, .toggle(4))
        try action(&lucky, .reroll(nil), values: [1])
        check(lucky.dice == [1, 1, 1, 1, 6], "held dice retained")
        var risk = try Session(definition: Definition.builtins[2], names: ["甲"])
        try action(&risk, .roll, values: [6])
        check(risk.pot == 12, "risk accumulates")
        try action(&risk, .roll, values: [1])
        check(risk.lastScore?.total == 0 && risk.phase == .receipt, "risk bust")
        var cap = try Session(definition: Definition.builtins[2], names: ["甲"])
        for _ in 0..<5 { try action(&cap, .roll, values: [6]) }
        check(cap.phase == .receipt && cap.player.score == 60, "risk cap auto banks")
        var invalid = Definition.builtins[0]
        invalid.rules.targets[0] = 19
        rejects("unreachable target") { try invalid.validate() }
        invalid.rules.targets[0] = 8
        rejects("duplicate target") { try invalid.validate() }
        var badName = Definition.builtins[0]
        badName.name = "坏\n名字"
        rejects("control characters in imported name") { try badName.validate() }
        for count in 1...4 {
            for d in Definition.builtins {
                var game = try Session(definition: d, names: (1...count).map { "玩家\($0)" })
                for _ in 0..<(d.rules.rounds * count) {
                    try action(&game, .roll, values: [2, 3, 5])
                    if d.template == .station {
                        try action(&game, .toggle(0))
                        try action(
                            &game,
                            .target(d.rules.targets.first { game.player.stations[$0] == nil }!))
                    }
                    if game.phase == .choosing { try action(&game, .confirm) }
                    try action(&game, .next)
                    try game.validate()
                }
                check(game.phase == .finished, "complete \(d.name) \(count) players")
            }
        }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = Store(directory: directory)
        try store.save(s)
        let restored = Store(directory: directory)
        check(restored.library.session == s, "exact save restore without reroll")
        var trial = s
        trial.trial = true
        try store.save(trial)
        check(store.library.session == s, "trial isolation")
        try store.save(streak)
        try store.save(streak)
        check(store.library.history.count == 1, "history idempotency")
        try Data("broken".utf8).write(to: directory.appendingPathComponent("library.json"))
        let recovery = Store(directory: directory)
        check(
            recovery.warning != nil && !recovery.blocked && recovery.library.history.count == 1,
            "corrupt primary recovers backup")
        check(
            store.library.personalBests[Library.bestKey(streak.definition)] == 11,
            "persistent personal best")
        try store.commit { $0.history = [] }
        check(
            Store(directory: directory).library.personalBests[Library.bestKey(streak.definition)]
                == 11, "personal best outlives history retention")
        let encoded = try JSONEncoder().encode(WorkFile(definition: d))
        let imported = try WorkFile.decode(encoded)
        check(
            imported.rules == d.rules && imported.id != d.id, "share roundtrip creates new identity"
        )
        rejects("oversize import") {
            _ = try WorkFile.decode(Data(repeating: 32, count: 1_048_577))
        }
        rejects("malformed import") { _ = try WorkFile.decode(Data("{}".utf8)) }
        rejects("future version import") {
            _ = try WorkFile.decode(JSONEncoder().encode(WorkFile(schemaVersion: 2, definition: d)))
        }
        var badSession = s
        badSession.dice = [9]
        rejects("corrupt session validation") { try badSession.validate() }
        let impossible = Store(directory: URL(fileURLWithPath: "/dev/null/not-a-directory"))
        rejects("write failure remains blocked") { try impossible.save(s) }
        check(impossible.library.session == nil, "write failure does not publish candidate")
        let failureDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        let failureStore = Store(directory: failureDir)
        try failureStore.save(s)
        try FileManager.default.removeItem(at: failureDir)
        try Data("blocks directory".utf8).write(to: failureDir)
        defer { try? FileManager.default.removeItem(at: failureDir) }
        rejects("mid-session disk failure") { try failureStore.save(streak) }
        check(
            failureStore.library.session == s && failureStore.library.history.isEmpty,
            "failed save retains reliable in-memory snapshot")
        var badDice = try Session(definition: Definition.builtins[0], names: ["甲"])
        let untouched = badDice
        rejects("invalid random draw atomicity") { try action(&badDice, .roll, values: [0]) }
        check(badDice == untouched, "invalid action leaves state unchanged")
        let receipt = try JSONDecoder().decode(Session.self, from: JSONEncoder().encode(s))
        check(receipt == s, "receipt roundtrip preserves revision and scores")
        print("\(count) checks passed")
    }

    static func tryScore(_ s: Session) -> Int { (try? s.preview().total) ?? -1 }
}

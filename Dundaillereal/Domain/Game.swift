import Foundation

enum RuleError: LocalizedError {
    case invalid(String)
    var errorDescription: String? {
        if case let .invalid(message) = self { return message }
        return nil
    }
}
enum Template: String, Codable, CaseIterable {
    case station, lucky, risk
    var title: String {
        switch self {
        case .station: return "Right on Track"
        case .lucky: return "Lucky Pairs"
        case .risk: return "Bank or Bust"
        }
    }
    var symbol: String {
        switch self {
        case .station: return "tram.fill"
        case .lucky: return "leaf.fill"
        case .risk: return "mountain.2.fill"
        }
    }
    var subtitle: String {
        switch self {
        case .station: return "Find your next stop"
        case .lucky: return "Keep a pair. Make it count."
        case .risk: return "Roll again or bank your points?"
        }
    }
}
struct Rules: Codable, Equatable {
    var dice = 3
    var rounds = 6
    var rerolls = 2
    var targets = [6, 8, 10, 12, 14, 16]
    var exact = 3
    var near = 1
    var streak = 3
    var bonus = 2
    var riskFace = 1
    var maxThrows = 5
}
struct Definition: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var template: Template
    var templateVersion = 1
    var rules = Rules()
    var imported = false
    static let builtins: [Definition] = Template.allCases.enumerated().map { index, type in
        var d = Definition(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000000\(index + 1)")!,
            name: type.title, template: type)
        if type == .lucky { d.rules.dice = 5 }
        if type == .risk { d.rules.dice = 2 }
        return d
    }

    func validate() throws {
        let r = rules
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, name.count <= 40,
            !name.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains)
        else { throw RuleError.invalid("Use 1–40 characters with no line breaks or control characters.") }
        guard templateVersion == 1 else { throw RuleError.invalid("This rule version is not supported. Please update the app.") }
        guard (1...5).contains(r.dice), (1...12).contains(r.rounds), (0...5).contains(r.rerolls),
            (1...10).contains(r.exact), (0...5).contains(r.near), (2...6).contains(r.streak),
            (0...10).contains(r.bonus), (1...6).contains(r.riskFace), (2...8).contains(r.maxThrows)
        else { throw RuleError.invalid("One or more rule values are outside the allowed range.") }
        if template == .station {
            guard r.targets.count == r.rounds, Set(r.targets).count == r.targets.count,
                r.targets.allSatisfy({ (1...(r.dice * 6)).contains($0) })
            else { throw RuleError.invalid("Use one unique stop per round, with targets from 1 to \(r.dice * 6).") }
        }
    }
    var summary: String {
        let r = rules
        switch template {
        case .station:
            return
                "Each player has \(r.rounds) rounds and \(r.dice) six-sided dice. Select one or more dice and an empty stop. An exact match earns \(r.exact) points; off by one earns \(r.near); otherwise 0. A zero still fills the stop. Each player may reroll one die \(r.rerolls) times per game. A streak of \(r.streak) exact matches earns \(r.bonus) bonus points, then resets. Stops: \(r.targets.map(String.init).joined(separator: ", "))."
        case .lucky:
            return
                "Each player has \(r.rounds) rounds and \(r.dice) six-sided dice. Tap dice to keep them and reroll the rest up to \(r.rerolls) times per round, or score immediately. Score the sum of all dice plus \(r.bonus) bonus points per matching pair (three alike count as one pair, four as two)."
        case .risk:
            return
                "Each player has \(r.rounds) rounds and rolls \(r.dice) six-sided dice. Rolling any \(r.riskFace) busts the round for 0 points. Otherwise, add the dice to your pot. Bank your points or roll again. After \(r.maxThrows) rolls in a round, the pot is banked automatically."
        }
    }
}
struct Player: Codable, Equatable {
    var name: String
    var score = 0
    var exactHits = 0
    var streak = 0
    var rerolls: Int
    var stations: [Int: Int] = [:]
}
enum Phase: String, Codable { case ready, choosing, receipt, finished }
enum ScoreReason: String, Codable { case exact, near, miss, pairs, bank, limit, bust }
struct Score: Codable, Equatable {
    var base: Int
    var bonus: Int
    var reason: String
    var reasonCode: ScoreReason = .bank
    var total: Int { base + bonus }
    var explanation: String { "\(reason) · Base \(base) + bonus \(bonus) = \(total) pts" }
}
enum Action { case roll, toggle(Int), target(Int), reroll(Int?), confirm, next }
struct Session: Codable, Equatable, Identifiable {
    var id = UUID()
    var definition: Definition
    var players: [Player]
    var revision = 0
    var turn = 0
    var phase = Phase.ready
    var dice: [Int] = []
    var selected: Set<Int> = []
    var target: Int?
    var throwCount = 0
    var turnRerolls = 0
    var pot = 0
    var lastScore: Score?
    var trial: Bool
    var created = Date()
    var current: Int { turn % players.count }
    var round: Int { turn / players.count + 1 }
    var player: Player { players[current] }

    init(definition: Definition, names: [String], trial: Bool = false) throws {
        try definition.validate()
        guard (1...4).contains(names.count),
            names.allSatisfy({
                !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.count <= 20
            })
        else { throw RuleError.invalid("Enter 1–4 player names, up to 20 characters each.") }
        self.definition = definition
        self.players = names.map { Player(name: $0, rerolls: definition.rules.rerolls) }
        self.trial = trial
        normalizeEnglishLabels()
    }

    func validate() throws {
        try definition.validate()
        guard (1...4).contains(players.count), revision >= 0, revision < 100000, pot >= 0,
            pot <= 240, turn >= 0, turn < definition.rules.rounds * players.count,
            dice.count == 0 || dice.count == definition.rules.dice,
            dice.allSatisfy({ (1...6).contains($0) }),
            selected.allSatisfy({ dice.indices.contains($0) }),
            throwCount >= 0, throwCount <= definition.rules.maxThrows, turnRerolls >= 0,
            turnRerolls <= definition.rules.rerolls,
            players.allSatisfy({
                !$0.name.isEmpty && $0.name.count <= 20 && (0...10000).contains($0.score)
                    && (0..<definition.rules.streak).contains($0.streak)
                    && (0...definition.rules.rounds).contains($0.exactHits)
                    && (0...definition.rules.rerolls).contains($0.rerolls)
                    && $0.stations.keys.allSatisfy(definition.rules.targets.contains)
            }),
            target == nil || definition.rules.targets.contains(target!),
            phase != .choosing || dice.count == definition.rules.dice,
            (phase != .receipt && phase != .finished) || lastScore != nil,
            phase != .ready
                || (dice.isEmpty && selected.isEmpty && target == nil && throwCount == 0),
            phase != .finished || turn == definition.rules.rounds * players.count - 1
        else { throw RuleError.invalid("The saved game is incomplete or invalid.") }
    }

    func preview() throws -> Score {
        let r = definition.rules
        switch definition.template {
        case .station:
            guard let target, player.stations[target] == nil, !selected.isEmpty else {
                throw RuleError.invalid("Select at least one die and an empty stop.")
            }
            let sum = selected.reduce(0) { $0 + dice[$1] }
            let distance = abs(sum - target)
            return Score(
                base: distance == 0 ? r.exact : (distance == 1 ? r.near : 0),
                bonus: distance == 0 && player.streak + 1 == r.streak ? r.bonus : 0,
                reason: "Total \(sum) → stop \(target): " + (distance == 0 ? "Exact match" : "Off by \(distance)"),
                reasonCode: distance == 0 ? .exact : (distance == 1 ? .near : .miss))
        case .lucky:
            let pairs = Dictionary(grouping: dice, by: { $0 }).values.reduce(0) {
                $0 + $1.count / 2
            }
            return Score(
                base: dice.reduce(0, +), bonus: pairs * r.bonus, reason: "Sum of all dice, \(pairs) matching pairs",
                reasonCode: .pairs)
        case .risk: return Score(base: pot, bonus: 0, reason: "Pot banked")
        }
    }

    mutating func apply(
        _ action: Action, revision expected: Int, roll: () -> Int = { Int.random(in: 1...6) }
    ) throws {
        guard revision == expected, phase != .finished else {
            throw RuleError.invalid("This action is out of date. Check the current turn.")
        }
        var next = self
        try next.perform(action, roll: roll)
        next.revision += 1
        self = next
    }

    private mutating func perform(_ action: Action, roll: () -> Int) throws {
        let r = definition.rules

        func draw() throws -> Int {
            let v = roll()
            guard (1...6).contains(v) else { throw RuleError.invalid("The random source returned an invalid die value.") }
            return v
        }
        switch action {
        case .roll:
            guard phase == .ready || (phase == .choosing && definition.template == .risk) else {
                throw RuleError.invalid("You cannot roll right now.")
            }
            dice = try (0..<r.dice).map { _ in try draw() }
            selected = []
            phase = .choosing
            throwCount += 1
            if definition.template == .risk {
                if dice.contains(r.riskFace) {
                    finish(
                        Score(
                            base: 0, bonus: 0, reason: "Rolled \(r.riskFace). Your pot of \(pot) points is lost.",
                            reasonCode: .bust))
                } else {
                    pot += dice.reduce(0, +)
                    if throwCount == r.maxThrows {
                        finish(
                            Score(base: pot, bonus: 0, reason: "Roll limit reached. Pot banked automatically.", reasonCode: .limit))
                    }
                }
            }
        case let .toggle(index):
            guard phase == .choosing, definition.template != .risk, dice.indices.contains(index)
            else { throw RuleError.invalid("You cannot select dice right now.") }
            if selected.contains(index) { selected.remove(index) } else { selected.insert(index) }
        case let .target(value):
            guard phase == .choosing, definition.template == .station, r.targets.contains(value),
                player.stations[value] == nil
            else { throw RuleError.invalid("This stop is unavailable.") }
            target = value
        case let .reroll(index):
            guard phase == .choosing else { throw RuleError.invalid("Roll the dice first.") }
            if definition.template == .station {
                guard let index, dice.indices.contains(index), player.rerolls > 0 else {
                    throw RuleError.invalid("No rerolls left in this game.")
                }
                dice[index] = try draw()
                players[current].rerolls -= 1
                selected = []
            } else if definition.template == .lucky {
                guard turnRerolls < r.rerolls, selected.count < dice.count else {
                    throw RuleError.invalid("No dice to reroll or no rerolls left.")
                }
                for i in dice.indices where !selected.contains(i) { dice[i] = try draw() }
                turnRerolls += 1
            } else {
                throw RuleError.invalid("Use Roll Again for this game.")
            }
        case .confirm:
            guard phase == .choosing else { throw RuleError.invalid("You cannot score right now.") }
            let score = try preview()
            if definition.template == .station, let target {
                let exact = selected.reduce(0) { $0 + dice[$1] } == target
                players[current].stations[target] = score.total
                players[current].exactHits += exact ? 1 : 0
                players[current].streak = exact ? (player.streak + 1) % r.streak : 0
            }
            finish(score)
        case .next:
            guard phase == .receipt else { throw RuleError.invalid("Finish the current action first.") }
            if turn + 1 == r.rounds * players.count {
                phase = .finished
            } else {
                turn += 1
                phase = .ready
                dice = []
                selected = []
                target = nil
                throwCount = 0
                turnRerolls = 0
                pot = 0
                lastScore = nil
            }
        }
    }

    private mutating func finish(_ score: Score) {
        players[current].score += score.total
        lastScore = score
        phase = .receipt
    }
}

/// English-only labels for imported content and pre-English saved games.
enum EnglishText {
    static func containsHan(_ text: String) -> Bool {
        text.unicodeScalars.contains {
            (0x3400...0x4DBF).contains($0.value) || (0x4E00...0x9FFF).contains($0.value)
                || (0xF900...0xFAFF).contains($0.value) || (0x20000...0x323AF).contains($0.value)
                || $0.value == 0x3007
        }
    }

    static func input(_ text: String) -> String {
        String(text.unicodeScalars.filter { (0x20...0x7E).contains($0.value) })
    }

    static func gameName(_ definition: Definition) -> String {
        guard containsHan(definition.name) else { return definition.name }
        if Definition.builtins.contains(where: { $0.id == definition.id }) {
            return definition.template.title
        }
        return definition.template.title + " " + definition.id.uuidString.prefix(4)
    }

    static func reason(_ score: Score) -> String {
        guard containsHan(score.reason) else { return score.reason }
        switch score.reasonCode {
        case .exact: return "Exact match"
        case .near: return "Off by one"
        case .miss: return "Target missed"
        case .pairs: return "Dice total and matching pairs"
        case .bank: return "Pot banked"
        case .limit: return "Roll limit reached. Pot banked."
        case .bust: return "Bust. No points this round."
        }
    }
}

extension Session {
    mutating func normalizeEnglishLabels() {
        definition.name = EnglishText.gameName(definition)
        for index in players.indices where EnglishText.containsHan(players[index].name) {
            players[index].name = "Player \(index + 1)"
        }
        if let score = lastScore { lastScore?.reason = EnglishText.reason(score) }
    }
}

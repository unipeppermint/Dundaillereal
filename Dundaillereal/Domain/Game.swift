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
        case .station: return "恰好到站"
        case .lucky: return "留点好运"
        case .risk: return "见好就收"
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
        case .station: return "每一站，都是新的惊喜"
        case .lucky: return "留下幸运，让好事成双"
        case .risk: return "再走一步，还是满载而归？"
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
        else { throw RuleError.invalid("名称需要 1～40 个字符，不能包含换行或控制字符") }
        guard templateVersion == 1 else { throw RuleError.invalid("不支持此模板版本，请更新应用") }
        guard (1...5).contains(r.dice), (1...12).contains(r.rounds), (0...5).contains(r.rerolls),
            (1...10).contains(r.exact), (0...5).contains(r.near), (2...6).contains(r.streak),
            (0...10).contains(r.bonus), (1...6).contains(r.riskFace), (2...8).contains(r.maxThrows)
        else { throw RuleError.invalid("规则参数超出允许范围") }
        if template == .station {
            guard r.targets.count == r.rounds, Set(r.targets).count == r.targets.count,
                r.targets.allSatisfy({ (1...(r.dice * 6)).contains($0) })
            else { throw RuleError.invalid("站点数量须等于轮数，不能重复，目标须在 1～\(r.dice * 6) 之间") }
        }
    }
    var summary: String {
        let r = rules
        switch template {
        case .station:
            return
                "每人 \(r.rounds) 轮，\(r.dice) 颗六面骰。选择至少一颗骰子与一个空站点：恰好命中 +\(r.exact) 分，相差 1 +\(r.near) 分，否则 0 分；0 分也填写站点。每人整局可重掷单颗骰子 \(r.rerolls) 次。连续精准 \(r.streak) 次额外 +\(r.bonus) 分，然后连击归零。目标：\(r.targets.map(String.init).joined(separator: "、"))。"
        case .lucky:
            return
                "每人 \(r.rounds) 轮，投 \(r.dice) 颗六面骰。点选保留任意骰子，其他骰子每回合最多重掷 \(r.rerolls) 次，也可直接计分。所有骰子的总和为基础分；每组相同点数按每对 +\(r.bonus) 分（3 颗算 1 对，4 颗算 2 对）。"
        case .risk:
            return
                "每人 \(r.rounds) 轮，每次投 \(r.dice) 颗六面骰。出现 \(r.riskFace) 点立即爆仓，本回合得 0 分；否则点数累加入背包。可收手入账或继续冒险。每回合最多投 \(r.maxThrows) 次，达到上限自动入账。"
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
    var explanation: String { "\(reason) · 基础 \(base) + 奖励 \(bonus) = \(total) 分" }
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
        else { throw RuleError.invalid("请填写 1～4 位玩家姓名，每个最多 20 字") }
        self.definition = definition
        self.players = names.map { Player(name: $0, rerolls: definition.rules.rerolls) }
        self.trial = trial
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
        else { throw RuleError.invalid("存档状态不完整或不合法") }
    }

    func preview() throws -> Score {
        let r = definition.rules
        switch definition.template {
        case .station:
            guard let target, player.stations[target] == nil, !selected.isEmpty else {
                throw RuleError.invalid("请选至少一颗骰子和一个未填写站点")
            }
            let sum = selected.reduce(0) { $0 + dice[$1] }
            let distance = abs(sum - target)
            return Score(
                base: distance == 0 ? r.exact : (distance == 1 ? r.near : 0),
                bonus: distance == 0 && player.streak + 1 == r.streak ? r.bonus : 0,
                reason: "合计 \(sum) → 目标 \(target)，" + (distance == 0 ? "精准到站" : "相差 \(distance)"),
                reasonCode: distance == 0 ? .exact : (distance == 1 ? .near : .miss))
        case .lucky:
            let pairs = Dictionary(grouping: dice, by: { $0 }).values.reduce(0) {
                $0 + $1.count / 2
            }
            return Score(
                base: dice.reduce(0, +), bonus: pairs * r.bonus, reason: "全部点数之和，\(pairs) 对相同点数",
                reasonCode: .pairs)
        case .risk: return Score(base: pot, bonus: 0, reason: "收手，背包入账")
        }
    }

    mutating func apply(
        _ action: Action, revision expected: Int, roll: () -> Int = { Int.random(in: 1...6) }
    ) throws {
        guard revision == expected, phase != .finished else {
            throw RuleError.invalid("操作已过期，请查看当前回合")
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
            guard (1...6).contains(v) else { throw RuleError.invalid("随机源返回无效点数") }
            return v
        }
        switch action {
        case .roll:
            guard phase == .ready || (phase == .choosing && definition.template == .risk) else {
                throw RuleError.invalid("当前不能投骰")
            }
            dice = try (0..<r.dice).map { _ in try draw() }
            selected = []
            phase = .choosing
            throwCount += 1
            if definition.template == .risk {
                if dice.contains(r.riskFace) {
                    finish(
                        Score(
                            base: 0, bonus: 0, reason: "出现 \(r.riskFace) 点，背包 \(pot) 分清空",
                            reasonCode: .bust))
                } else {
                    pot += dice.reduce(0, +)
                    if throwCount == r.maxThrows {
                        finish(
                            Score(base: pot, bonus: 0, reason: "达到投掷上限，自动入账", reasonCode: .limit))
                    }
                }
            }
        case let .toggle(index):
            guard phase == .choosing, definition.template != .risk, dice.indices.contains(index)
            else { throw RuleError.invalid("当前不能选择骰子") }
            if selected.contains(index) { selected.remove(index) } else { selected.insert(index) }
        case let .target(value):
            guard phase == .choosing, definition.template == .station, r.targets.contains(value),
                player.stations[value] == nil
            else { throw RuleError.invalid("站点不可用") }
            target = value
        case let .reroll(index):
            guard phase == .choosing else { throw RuleError.invalid("请先投骰") }
            if definition.template == .station {
                guard let index, dice.indices.contains(index), player.rerolls > 0 else {
                    throw RuleError.invalid("本局重掷次数已用完")
                }
                dice[index] = try draw()
                players[current].rerolls -= 1
                selected = []
            } else if definition.template == .lucky {
                guard turnRerolls < r.rerolls, selected.count < dice.count else {
                    throw RuleError.invalid("没有可重掷的骰子或次数已用完")
                }
                for i in dice.indices where !selected.contains(i) { dice[i] = try draw() }
                turnRerolls += 1
            } else {
                throw RuleError.invalid("此玩法请使用继续冒险")
            }
        case .confirm:
            guard phase == .choosing else { throw RuleError.invalid("当前不能计分") }
            let score = try preview()
            if definition.template == .station, let target {
                let exact = selected.reduce(0) { $0 + dice[$1] } == target
                players[current].stations[target] = score.total
                players[current].exactHits += exact ? 1 : 0
                players[current].streak = exact ? (player.streak + 1) % r.streak : 0
            }
            finish(score)
        case .next:
            guard phase == .receipt else { throw RuleError.invalid("请先完成当前行动") }
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

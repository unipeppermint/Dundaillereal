import UIKit
import AudioToolbox

final class EditorPage: Page {
    var definition: Definition
    var fields: [String: UITextField] = [:]
    let status = UILabel()
    init(definition: Definition, copying: Bool) {
        self.definition = definition
        if copying { self.definition.id = UUID(); self.definition.name = "我的" + definition.template.title; self.definition.imported = false }
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "规则工坊"
        label("\(definition.template.title) · 受限模板", style: .title2)
        field("name", "作品名称（1～40 字）", definition.name, numeric: false)
        field("dice", "六面骰数量（1～5）", "\(definition.rules.dice)")
        field("rounds", "每人轮数（1～12）", "\(definition.rules.rounds)")
        if definition.template != .risk { field("rerolls", definition.template == .station ? "每人整局单颗重掷次数（0～5）" : "每回合重掷次数（0～5）", "\(definition.rules.rerolls)") }
        if definition.template == .station {
            field("targets", "目标站点（逗号分隔，与轮数一致）", definition.rules.targets.map(String.init).joined(separator: ","), numeric: false)
            field("exact", "精准到站得分（1～10）", "\(definition.rules.exact)")
            field("near", "相差 1 得分（0～5）", "\(definition.rules.near)")
            field("streak", "连续精准次数（2～6）", "\(definition.rules.streak)")
        }
        if definition.template != .risk { field("bonus", definition.template == .station ? "连击奖励（0～10）" : "每对相同点数奖励（0～10）", "\(definition.rules.bonus)") }
        if definition.template == .risk { field("riskFace", "爆仓点数（1～6）", "\(definition.rules.riskFace)"); field("maxThrows", "每回合最多投骰次数（2～8）", "\(definition.rules.maxThrows)") }
        status.numberOfLines = 0; status.font = .preferredFont(forTextStyle: .body); status.adjustsFontForContentSizeCategory = true; stack.addArrangedSubview(status)
        button("保存作品", primary: true) { do { let d = try self.read(); try Store.shared.commit { if let index = $0.works.firstIndex(where: { $0.id == d.id }) { $0.works[index] = d } else { $0.works.append(d) } }; self.definition = d; self.message("已保存", "作品已收入工坊，正在进行的对局仍使用原规则。") } catch { self.error(error) } }
        button("试玩这套规则") { do { self.push(PlayPage(session: try Session(definition: self.read(), names: ["试玩玩家"], trial: true))) } catch { self.error(error) } }
        update()
    }
    func field(_ key: String, _ title: String, _ value: String, numeric: Bool = true) {
        label(title, style: .subheadline); let text = UITextField(); text.text = value; text.borderStyle = .roundedRect; text.backgroundColor = .white; text.textColor = Theme.ink; text.font = .preferredFont(forTextStyle: .body); text.adjustsFontForContentSizeCategory = true; text.keyboardType = numeric ? .numberPad : .default; text.inputAccessoryView = keyboardToolbar(); text.accessibilityLabel = title; text.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true; text.addAction(UIAction { [weak self] _ in self?.update() }, for: .editingChanged); fields[key] = text; stack.addArrangedSubview(text)
    }
    func read() throws -> Definition {
        var d = definition; d.name = fields["name"]?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        func int(_ key: String, _ original: Int) throws -> Int { guard let field = fields[key] else { return original }; guard let v = Int(field.text ?? "") else { throw RuleError.invalid("请填写有效整数") }; return v }
        d.rules.dice = try int("dice", d.rules.dice); d.rules.rounds = try int("rounds", d.rules.rounds); d.rules.rerolls = try int("rerolls", d.rules.rerolls)
        d.rules.exact = try int("exact", d.rules.exact); d.rules.near = try int("near", d.rules.near); d.rules.streak = try int("streak", d.rules.streak); d.rules.bonus = try int("bonus", d.rules.bonus); d.rules.riskFace = try int("riskFace", d.rules.riskFace); d.rules.maxThrows = try int("maxThrows", d.rules.maxThrows)
        if let text = fields["targets"]?.text {
            d.rules.targets = try text.replacingOccurrences(of: "，", with: ",").components(separatedBy: ",").map { guard let value = Int($0.trimmingCharacters(in: .whitespaces)) else { throw RuleError.invalid("站点请用逗号分隔整数") }; return value }
        }
        try d.validate(); return d
    }
    func update() { do { let d = try read(); status.text = "✓ 规则检查通过（不代表平衡性验证）\n\n" + d.summary; status.textColor = Theme.sage } catch { status.text = error.localizedDescription; status.textColor = Theme.coral } }
}
final class PlayersPage: Page {
    let definition: Definition
    var names: [UITextField] = []
    let count = UISegmentedControl(items: ["1 人", "2 人", "3 人", "4 人"])
    init(definition: Definition) { self.definition = definition; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "一起上桌"; label(definition.name, style: .title1); label("同一台手机，依次传给当前玩家。", style: .subheadline); count.selectedSegmentIndex = 0; stack.addArrangedSubview(count)
        for i in 0..<4 { let field = UITextField(); field.text = "玩家 \(i + 1)"; field.font = .preferredFont(forTextStyle: .body); field.adjustsFontForContentSizeCategory = true; field.borderStyle = .roundedRect; field.inputAccessoryView = keyboardToolbar(); field.accessibilityLabel = "玩家 \(i + 1) 姓名"; field.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true; names.append(field); stack.addArrangedSubview(field) }
        count.addAction(UIAction { [weak self] _ in self?.update() }, for: .valueChanged); update()
        button("开局", primary: true) {
            if Store.shared.library.session != nil { self.confirm("替换正在进行的对局？", message: "正式存档只保留一局。继续开局会替换旧进度；可取消后返回游戏桌继续上局。") { self.start() } } else { self.start() }
        }
    }
    func update() { for (i,f) in names.enumerated() { f.isHidden = i > count.selectedSegmentIndex } }
    func start() { do { let s = try Session(definition: definition, names: names.prefix(count.selectedSegmentIndex + 1).map { ($0.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }); try Store.shared.save(s); let page = PlayPage(session: s); var vcs = navigationController?.viewControllers ?? []; vcs.removeLast(); vcs.append(page); navigationController?.setViewControllers(vcs, animated: true) } catch { self.error(error) } }
}
final class PlayPage: Page {
    var session: Session
    init(session: Session) { self.session = session; super.init(nibName: nil, bundle: nil); hidesBottomBarWhenPushed = true }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() { super.viewDidLoad(); navigationItem.largeTitleDisplayMode = .never; navigationItem.rightBarButtonItem = UIBarButtonItem(title: "规则", style: .plain, target: self, action: #selector(rules)); render() }
    @objc func rules() { message(session.definition.name, session.definition.summary) }
    func act(_ action: Action, revision: Int) {
        do {
            var candidate = session; try candidate.apply(action, revision: revision); try Store.shared.save(candidate); session = candidate
            if case .roll = action {
                if UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                if UserDefaults.standard.object(forKey: "sound") as? Bool ?? true { AudioServicesPlaySystemSound(1104) }
            }
            render()
            if !UIAccessibility.isReduceMotionEnabled {
                let dice = stack.arrangedSubviews.compactMap { $0 as? UIStackView }.flatMap { $0.arrangedSubviews }.compactMap { $0 as? DiceButton }
                let rolling: Bool
                switch action { case .roll, .reroll: rolling = true; default: rolling = false }
                if rolling {
                    stack.isUserInteractionEnabled = false
                    dice.forEach { $0.transform = CGAffineTransform(scaleX: 0.85, y: 0.85).rotated(by: -0.12) }
                    UIView.animate(withDuration: 0.2, animations: { dice.forEach { $0.transform = .identity } }, completion: { _ in self.stack.isUserInteractionEnabled = true })
                }
            }
            UIAccessibility.post(notification: .layoutChanged, argument: stack.arrangedSubviews.first)
        } catch { self.error(error) }
    }
    func actionButton(_ title: String, _ action: Action, primary: Bool = false) { let revision = session.revision; button(title, primary: primary) { self.act(action, revision: revision) } }
    func render() {
        clear(); title = session.definition.name
        if session.trial { label("试玩 · 不写入正式进度或历史", style: .caption1, color: Theme.coral) }
        if session.phase == .finished { results(); return }
        label("第 \(session.round) / \(session.definition.rules.rounds) 轮", style: .subheadline)
        label(session.players.enumerated().map { i,p in "\(i == session.current ? "▶ " : "")\(p.name)  \(p.score) 分" }.joined(separator: "    "), style: .headline)
        label("\(session.player.name) 的回合", style: .title1)
        if session.phase == .ready {
            cover(session.definition.template); label("请把手机交给 \(session.player.name)，准备好后投骰。")
            actionButton("投出骰子", .roll, primary: true); return
        }
        if !session.dice.isEmpty {
            let row = UIStackView(); row.axis = .horizontal; row.spacing = 9; row.distribution = .fillEqually
            let revision = session.revision
            for (i,v) in session.dice.enumerated() { let die = DiceButton(value: v, selected: session.selected.contains(i)) { self.act(.toggle(i), revision: revision) }; die.isEnabled = session.phase == .choosing && session.definition.template != .risk; die.accessibilityIdentifier = "die-\(i)"; row.addArrangedSubview(die) }; stack.addArrangedSubview(row)
        }
        if session.phase == .receipt {
            label(session.lastScore?.explanation ?? "", style: .title2, color: Theme.sage)
            label("本次得分已入账\(session.trial ? "（试玩）" : "并保存")。", style: .subheadline)
            actionButton(session.turn + 1 == session.players.count * session.definition.rules.rounds ? "查看结算" : "传给下一位玩家", .next, primary: true); return
        }
        switch session.definition.template {
        case .station:
            label("点选骰子组合 · 合计 \(session.selected.reduce(0) { $0 + session.dice[$1] })", style: .headline)
            label("选择一个站点（✓ 表示已填写）", style: .subheadline)
            let boardRevision = session.revision
            if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
                for target in session.definition.rules.targets {
                    if let score = session.player.stations[target] { label("✓ 站点 \(target) · \(score)分") }
                    else { actionButton("站点 \(target)", .target(target), primary: session.target == target) }
                }
            } else {
                stack.addArrangedSubview(RouteBoard(targets: session.definition.rules.targets, scores: session.player.stations, selected: session.target) { self.act(.target($0), revision: boardRevision) })
            }
            if let preview = try? session.preview() { label("预计：" + preview.explanation, color: Theme.coral) }
            else { label("选好骰子与站点后，将显示预计得分。", style: .footnote) }
            label("本局剩余重掷 \(session.player.rerolls) 次 · 连续精准 \(session.player.streak) 次", style: .footnote)
            if session.player.rerolls > 0 {
                let revision = session.revision
                button("重掷一颗 · 本局剩余 \(session.player.rerolls) 次") {
                    let sheet = UIAlertController(title: "选择要重掷的骰子", message: "重掷后需要重新选择点数组合。", preferredStyle: .actionSheet)
                    for i in self.session.dice.indices { sheet.addAction(UIAlertAction(title: "第 \(i + 1) 颗 · \(self.session.dice[i]) 点", style: .default) { _ in self.act(.reroll(i), revision: revision) }) }
                    sheet.addAction(UIAlertAction(title: "取消", style: .cancel)); sheet.popoverPresentationController?.sourceView = self.view
                    self.present(sheet, animated: true)
                }
            }
            let revision = session.revision; let b = button("确认到站", primary: true) { self.act(.confirm, revision: revision) }; b.isEnabled = (try? session.preview()) != nil
        case .lucky:
            label("点选要保留的骰子；计分会计算全部骰子。", style: .subheadline)
            label("本回合剩余重掷 \(session.definition.rules.rerolls - session.turnRerolls) 次")
            if let score = try? session.preview() { label("预计：" + score.explanation, color: Theme.coral) }
            if session.turnRerolls < session.definition.rules.rerolls && session.selected.count < session.dice.count { actionButton("重掷未保留的骰子", .reroll(nil)) }
            actionButton("保留好运 · 计分", .confirm, primary: true)
        case .risk:
            cover(.risk, height: 120); label("背包 · \(session.pot) 分", style: .largeTitle); label("已投 \(session.throwCount) / \(session.definition.rules.maxThrows) 次。出现 \(session.definition.rules.riskFace) 点，本回合归零。")
            actionButton("见好就收 · 入账", .confirm, primary: true); actionButton("继续冒险", .roll)
        }
    }
    func results() {
        label(session.trial ? "试玩完成" : "这一局，值得珍藏", style: .largeTitle); cover(session.definition.template)
        let best = session.players.map(\.score).max() ?? 0
        if session.players.count == 1 {
            label("本局 \(best) 分 · 精准 \(session.player.exactHits) 次", style: .title2)
            if !session.trial { let record = Store.shared.library.personalBests[Library.bestKey(session.definition)] ?? best; label("同规则个人最佳 · \(record) 分") }
        } else { let winners = session.players.filter { $0.score == best }.map(\.name); label((winners.count > 1 ? "并列获胜：" : "获胜：") + winners.joined(separator: "、"), style: .title2) }
        for p in session.players { label("\(p.name)  ·  \(p.score) 分", style: .headline) }
        button("改成我的玩法") { self.push(EditorPage(definition: self.session.definition, copying: true)) }
        button("回到游戏桌", primary: true) { self.navigationController?.popToRootViewController(animated: true) }
    }
}

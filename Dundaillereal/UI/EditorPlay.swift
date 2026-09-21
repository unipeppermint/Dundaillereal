import UIKit

final class EditorPage: Page {
    var definition: Definition
    var fields: [String: UITextField] = [:]
    let status = UILabel()
    private var fieldCards: [String: UIView] = [:]
    private var ruleGroups: [String: RuleDisclosure] = [:]

    init(definition: Definition, copying: Bool) {
        self.definition = definition
        if copying {
            self.definition.id = UUID()
            self.definition.name = "我的" + definition.template.title
            self.definition.imported = false
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "规则工坊"
        stack.spacing = 12
        field("name", "作品名称（1～40 字）", definition.name, numeric: false)
        field("dice", "六面骰数量（1～5）", "\(definition.rules.dice)")
        field("rounds", "每人轮数（1～12）", "\(definition.rules.rounds)")
        if definition.template != .risk {
            field(
                "rerolls", definition.template == .station ? "每人整局单颗重掷次数（0～5）" : "每回合重掷次数（0～5）",
                "\(definition.rules.rerolls)")
        }
        if definition.template == .station {
            field(
                "targets", "目标站点（逗号分隔，与轮数一致）",
                definition.rules.targets.map(String.init).joined(separator: ","), numeric: false)
            field("exact", "精准到站得分（1～10）", "\(definition.rules.exact)")
            field("near", "相差 1 得分（0～5）", "\(definition.rules.near)")
            field("streak", "连续精准次数（2～6）", "\(definition.rules.streak)")
        }
        if definition.template != .risk {
            field(
                "bonus", definition.template == .station ? "连击奖励（0～10）" : "每对相同点数奖励（0～10）",
                "\(definition.rules.bonus)")
        }
        if definition.template == .risk {
            field("riskFace", "爆仓点数（1～6）", "\(definition.rules.riskFace)")
            field("maxThrows", "每回合最多投骰次数（2～8）", "\(definition.rules.maxThrows)")
        }
        let groups: [(String, String, String, [String])] = [
            ("骰子配置", "dice", "\(definition.rules.dice)颗六面骰", ["dice"]),
            ("回合动作", "hand.tap", definition.template == .risk ? "继续冒险 · 适时收手" : "选择骰子 · 有限重掷", ["rerolls", "riskFace", "maxThrows"]),
            ("得分规则", "star", definition.template == .station ? "恰好到站 +\(definition.rules.exact)分" : "按点数组合计分", definition.template == .lucky ? ["bonus"] : ["exact", "near"]),
            ("特殊奖励", "gift", definition.template == .station ? "连续命中 +\(definition.rules.bonus)分" : "遵循当前模板规则", definition.template == .station ? ["streak", "bonus"] : []),
            ("结束条件", "flag", "完成\(definition.rules.rounds)回合", ["rounds", "targets"]),
        ]
        for (title, symbol, summary, keys) in groups {
            var cards = keys.compactMap { fieldCards[$0] }
            for card in cards { card.removeFromSuperview() }
            if cards.isEmpty {
                cards = [styledLabel(definition.template == .risk ? "出现爆仓点数，本回合得分归零。" : "本项由玩法模板决定。", .footnote)]
            }
            let group = RuleDisclosure(title: title, symbol: symbol, summary: summary, fields: cards)
            ruleGroups[title] = group
            stack.addArrangedSubview(group)
        }
        status.numberOfLines = 0
        status.font = .preferredFont(forTextStyle: .footnote)
        status.adjustsFontForContentSizeCategory = true
        stack.addArrangedSubview(status)
        paperGroup([status], tint: Theme.sage.withAlphaComponent(0.12))
        let save = button("保存作品", primary: true) {
            do {
                let d = try self.read()
                try Store.shared.commit {
                    if let index = $0.works.firstIndex(where: { $0.id == d.id }) {
                        $0.works[index] = d
                    } else {
                        $0.works.append(d)
                    }
                }
                self.definition = d
                self.message("已保存", "作品已收入工坊，正在进行的对局仍使用原规则。")
            } catch { self.error(error) }
        }
        save.removeFromSuperview()
        save.configuration = .plain()
        save.setTitle("保存", for: .normal)
        save.setTitleColor(Theme.coral, for: .normal)
        save.accessibilityLabel = "保存作品"
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: save)
        let trial = button("试玩这套规则", primary: true) {
            do {
                self.push(
                    PlayPage(
                        session: try Session(definition: self.read(), names: ["试玩玩家"], trial: true))
                )
            } catch { self.error(error) }
        }
        trial.configuration?.baseBackgroundColor = Theme.ink
        update()
    }

    func field(_ key: String, _ title: String, _ value: String, numeric: Bool = true) {
        let heading = label(title, style: .subheadline)
        let text = UITextField()
        text.text = value
        text.borderStyle = .roundedRect
        text.backgroundColor = .white
        text.textColor = Theme.ink
        text.font = .preferredFont(forTextStyle: .body)
        text.adjustsFontForContentSizeCategory = true
        text.keyboardType = numeric ? .numberPad : .default
        text.inputAccessoryView = keyboardToolbar()
        text.accessibilityLabel = title
        text.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        text.addAction(UIAction { [weak self] _ in self?.update() }, for: .editingChanged)
        fields[key] = text
        stack.addArrangedSubview(text)
        text.borderStyle = .none
        text.backgroundColor = Theme.paper
        text.layer.cornerRadius = 10
        let spacer = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        text.leftView = spacer
        text.leftViewMode = .always
        if key == "name" {
            heading.text = "游戏名称"
            heading.font = .preferredFont(forTextStyle: .caption1)
            stack.setCustomSpacing(6, after: heading)
            return
        }
        let iconNames = [
            "name": "pencil", "dice": "dice", "rounds": "flag",
            "rerolls": "arrow.triangle.2.circlepath",
            "targets": "point.topleft.down.curvedto.point.bottomright.up", "exact": "star",
            "near": "smallcircle.filled.circle", "streak": "flame", "bonus": "gift",
            "riskFace": "exclamationmark.triangle", "maxThrows": "flag.checkered",
        ]
        let icon = UIImageView(image: UIImage(systemName: iconNames[key] ?? "slider.horizontal.3"))
        icon.tintColor = Theme.ink
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        let row = UIStackView()
        row.spacing = 12
        row.alignment = .center
        heading.removeFromSuperview()
        row.addArrangedSubview(icon)
        row.addArrangedSubview(heading)
        paperGroup([row, text])
        fieldCards[key] = stack.arrangedSubviews.last
    }

    func read() throws -> Definition {
        var d = definition
        d.name = fields["name"]?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        func int(_ key: String, _ original: Int) throws -> Int {
            guard let field = fields[key] else { return original }
            guard let v = Int(field.text ?? "") else { throw RuleError.invalid("请填写有效整数") }
            return v
        }
        d.rules.dice = try int("dice", d.rules.dice)
        d.rules.rounds = try int("rounds", d.rules.rounds)
        d.rules.rerolls = try int("rerolls", d.rules.rerolls)
        d.rules.exact = try int("exact", d.rules.exact)
        d.rules.near = try int("near", d.rules.near)
        d.rules.streak = try int("streak", d.rules.streak)
        d.rules.bonus = try int("bonus", d.rules.bonus)
        d.rules.riskFace = try int("riskFace", d.rules.riskFace)
        d.rules.maxThrows = try int("maxThrows", d.rules.maxThrows)
        if let text = fields["targets"]?.text {
            d.rules.targets = try text.replacingOccurrences(of: "，", with: ",").components(
                separatedBy: ","
            ).map {
                guard let value = Int($0.trimmingCharacters(in: .whitespaces)) else {
                    throw RuleError.invalid("站点请用逗号分隔整数")
                }
                return value
            }
        }
        try d.validate()
        return d
    }

    func update() {
        do {
            let d = try read()
            ruleGroups["骰子配置"]?.setSummary("\(d.rules.dice)颗六面骰")
            ruleGroups["结束条件"]?.setSummary("完成\(d.rules.rounds)回合")
            if d.template == .station {
                ruleGroups["得分规则"]?.setSummary("恰好到站 +\(d.rules.exact)分")
                ruleGroups["特殊奖励"]?.setSummary("连续\(d.rules.streak)次命中 +\(d.rules.bonus)分")
            }
            status.text = "✓ 规则检查通过\n当前规则可以正常游玩"
            status.accessibilityHint = d.summary
            status.textColor = Theme.sage
        } catch {
            status.text = error.localizedDescription
            status.textColor = Theme.coral
        }
    }
}
final class PlayersPage: Page {
    let definition: Definition
    var names: [UITextField] = []
    let count = UISegmentedControl(items: ["1 人", "2 人", "3 人", "4 人"])

    init(definition: Definition) {
        self.definition = definition
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "一起上桌"
        label(definition.name, style: .title1)
        label("同一台手机，依次传给当前玩家。", style: .subheadline)
        count.selectedSegmentIndex = 0
        stack.addArrangedSubview(count)
        for i in 0..<4 {
            let field = UITextField()
            field.text = "玩家 \(i + 1)"
            field.font = .preferredFont(forTextStyle: .body)
            field.adjustsFontForContentSizeCategory = true
            field.borderStyle = .roundedRect
            field.inputAccessoryView = keyboardToolbar()
            field.accessibilityLabel = "玩家 \(i + 1) 姓名"
            field.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
            names.append(field)
            stack.addArrangedSubview(field)
        }
        count.addAction(UIAction { [weak self] _ in self?.update() }, for: .valueChanged)
        update()
        button("开局", primary: true) {
            if Store.shared.library.session != nil {
                self.confirm("替换正在进行的对局？", message: "正式存档只保留一局。继续开局会替换旧进度；可取消后返回游戏桌继续上局。") {
                    self.start()
                }
            } else {
                self.start()
            }
        }
    }

    func update() {
        for (i, f) in names.enumerated() { f.isHidden = i > count.selectedSegmentIndex }
    }

    func start() {
        do {
            let s = try Session(
                definition: definition,
                names: names.prefix(count.selectedSegmentIndex + 1).map {
                    ($0.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                })
            try Store.shared.save(s)
            let page = PlayPage(session: s)
            var vcs = navigationController?.viewControllers ?? []
            vcs.removeLast()
            vcs.append(page)
            navigationController?.setViewControllers(vcs, animated: true)
        } catch { self.error(error) }
    }
}
final class PlayPage: Page {
    var session: Session
    private var rollPresentation: DiceRollPresentation?
    private var isRolling = false

    init(session: Session) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "规则", style: .plain, target: self, action: #selector(rules))
        NotificationCenter.default.addObserver(self, selector: #selector(interruptRoll), name: UIApplication.willResignActiveNotification, object: nil)
        render()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        interruptRoll()
    }

    @objc private func interruptRoll() {
        guard isRolling else { return }
        isRolling = false
        let presentation = rollPresentation
        rollPresentation = nil
        presentation?.cancel()
        render()
    }

    @objc func rules() { guard !isRolling else { return }; message(session.definition.name, session.definition.summary) }
    func act(_ action: Action, revision: Int) {
        guard !isRolling else { return }
        do {
            var moving = Set<Int>()
            switch action {
            case .roll: moving = Set(0..<session.definition.rules.dice)
            case let .reroll(index):
                if let index { moving = [index] }
                else { moving = Set(session.dice.indices).subtracting(session.selected) }
            default: break
            }
            var candidate = session
            try candidate.apply(action, revision: revision)
            try Store.shared.save(candidate)
            session = candidate
            guard !moving.isEmpty else {
                render()
                UIAccessibility.post(notification: .layoutChanged, argument: stack.arrangedSubviews.first)
                return
            }
            isRolling = true
            let presentation = DiceRollPresentation(values: session.dice, moving: moving) { [weak self] in
                guard let self, self.isRolling, let overlay = self.rollPresentation else { return }
                self.render()
                self.view.bringSubviewToFront(overlay)
                // The saved results are revealed only when all moving dice have settled.
                UIView.animate(withDuration: UIAccessibility.isReduceMotionEnabled ? 0.1 : 0.16, animations: {
                    overlay.alpha = 0
                }, completion: { [weak self, weak overlay] _ in
                    overlay?.cancel()
                    guard let self, self.rollPresentation === overlay else { return }
                    self.rollPresentation = nil
                    self.isRolling = false
                    UIAccessibility.post(notification: .announcement, argument: "投掷完成，" + self.session.dice.map { "\($0) 点" }.joined(separator: "、"))
                })
            }
            presentation.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(presentation)
            NSLayoutConstraint.activate([
                presentation.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                presentation.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                presentation.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                presentation.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
            rollPresentation = presentation
            view.layoutIfNeeded()
            presentation.start()
        } catch { self.error(error) }
    }

    func actionButton(_ title: String, _ action: Action, primary: Bool = false) {
        let revision = session.revision
        let b = button(title, primary: primary) { self.act(action, revision: revision) }
        if primary { pinPrimary(b) }
    }

    func render() {
        clear()
        title = session.definition.name
        if session.trial { label("试玩 · 不写入正式进度或历史", style: .caption1, color: Theme.coral) }
        if session.phase == .finished {
            results()
            return
        }
        stack.spacing = 8
        let round = label("第 \(session.round) / \(session.definition.rules.rounds) 轮", style: .caption1)
        round.textAlignment = .center
        playerBadges(session)
        if session.phase == .choosing && session.definition.template == .station
            && !traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            renderStationTable()
            return
        }
        if session.phase == .ready {
            cover(session.definition.template)
            label("请把手机交给 \(session.player.name)，准备好后投骰。")
            actionButton("投出骰子", .roll, primary: true)
            return
        }
        if session.phase == .choosing && session.definition.template == .station {
            label("选择一个站点（✓ 表示已填写）", style: .subheadline)
            let boardRevision = session.revision
            if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
                for target in session.definition.rules.targets {
                    if let score = session.player.stations[target] {
                        label("✓ 站点 \(target) · \(score)分")
                    } else {
                        actionButton(
                            "站点 \(target)", .target(target), primary: session.target == target)
                    }
                }
            } else {
                stack.addArrangedSubview(
                    RouteBoard(
                        targets: session.definition.rules.targets, scores: session.player.stations,
                        selected: session.target
                    ) { self.act(.target($0), revision: boardRevision) })
            }
        }
        if !session.dice.isEmpty {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 14
            row.distribution = .fillEqually
            row.isLayoutMarginsRelativeArrangement = true
            row.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 18, right: 14)
            row.backgroundColor = UIColor.white.withAlphaComponent(0.5)
            row.layer.cornerRadius = 18
            let revision = session.revision
            for (i, v) in session.dice.enumerated() {
                let die = DiceButton(value: v, selected: session.selected.contains(i)) {
                    self.act(.toggle(i), revision: revision)
                }
                die.isEnabled = session.phase == .choosing && session.definition.template != .risk
                die.accessibilityIdentifier = "die-\(i)"
                row.addArrangedSubview(die)
            }
            stack.addArrangedSubview(row)
        }
        if session.phase == .receipt {
            label(session.lastScore?.explanation ?? "", style: .title2, color: Theme.sage)
            label("本次得分已入账\(session.trial ? "（试玩）" : "并保存")。", style: .subheadline)
            actionButton(
                session.turn + 1 == session.players.count * session.definition.rules.rounds
                    ? "查看结算" : "传给下一位玩家", .next, primary: true)
            return
        }
        switch session.definition.template {
        case .station:
            label(
                "点选骰子组合 · 合计 \(session.selected.reduce(0) { $0 + session.dice[$1] })",
                style: .headline)
            if let preview = try? session.preview() {
                label("预计：" + preview.explanation, color: Theme.coral)
            } else {
                label("选好骰子与站点后，将显示预计得分。", style: .footnote)
            }
            label(
                "本局剩余重掷 \(session.player.rerolls) 次 · 连续精准 \(session.player.streak) 次",
                style: .footnote)
            if session.player.rerolls > 0 {
                let revision = session.revision
                button("重掷一颗 · 本局剩余 \(session.player.rerolls) 次") {
                    let sheet = UIAlertController(
                        title: "选择要重掷的骰子", message: "重掷后需要重新选择点数组合。", preferredStyle: .actionSheet)
                    for i in self.session.dice.indices {
                        sheet.addAction(
                            UIAlertAction(
                                title: "第 \(i + 1) 颗 · \(self.session.dice[i]) 点", style: .default
                            ) { _ in self.act(.reroll(i), revision: revision) })
                    }
                    sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
                    sheet.popoverPresentationController?.sourceView = self.view
                    self.present(sheet, animated: true)
                }
            }
            let revision = session.revision
            let b = button("确认到站", primary: true) { self.act(.confirm, revision: revision) }
            b.isEnabled = (try? session.preview()) != nil
            pinPrimary(b)
        case .lucky:
            label("点选要保留的骰子；计分会计算全部骰子。", style: .subheadline)
            label("本回合剩余重掷 \(session.definition.rules.rerolls - session.turnRerolls) 次")
            if let score = try? session.preview() {
                label("预计：" + score.explanation, color: Theme.coral)
            }
            if session.turnRerolls < session.definition.rules.rerolls
                && session.selected.count < session.dice.count
            {
                actionButton("重掷未保留的骰子", .reroll(nil))
            }
            actionButton("保留好运 · 计分", .confirm, primary: true)
        case .risk:
            cover(.risk, height: 120)
            label("背包 · \(session.pot) 分", style: .largeTitle)
            label(
                "已投 \(session.throwCount) / \(session.definition.rules.maxThrows) 次。出现 \(session.definition.rules.riskFace) 点，本回合归零。"
            )
            actionButton("见好就收 · 入账", .confirm, primary: true)
            actionButton("继续冒险", .roll)
        }
    }

    private func renderStationTable() {
        let revision = session.revision
        let usableHeight = view.bounds.height - max(view.safeAreaInsets.top, 64) - max(view.safeAreaInsets.bottom, 20)
        let board = RouteBoard(targets: session.definition.rules.targets, scores: session.player.stations,
                               selected: session.target, height: max(200, min(430, usableHeight - 370))) {
            self.act(.target($0), revision: revision)
        }
        stack.addArrangedSubview(board)
        let tray = PaperCard(inset: 12)
        tray.content.spacing = 6
        tray.backgroundColor = UIColor(red: 0.99, green: 0.974, blue: 0.935, alpha: 1)
        let row = UIStackView()
        row.spacing = 10
        row.distribution = .fillEqually
        let count = CGFloat(session.dice.count)
        let size = min(76, (view.bounds.width - 78 - (count - 1) * 10) / count)
        for (index, value) in session.dice.enumerated() {
            let die = DiceButton(value: value, selected: session.selected.contains(index)) {
                self.act(.toggle(index), revision: revision)
            }
            die.accessibilityIdentifier = "die-\(index)"
            row.addArrangedSubview(die)
        }
        let holder = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        holder.addSubview(row)
        NSLayoutConstraint.activate([
            holder.heightAnchor.constraint(equalToConstant: size + 4),
            row.centerXAnchor.constraint(equalTo: holder.centerXAnchor), row.topAnchor.constraint(equalTo: holder.topAnchor),
            row.widthAnchor.constraint(equalToConstant: size * count + (count - 1) * 10),
        ])
        tray.content.addArrangedSubview(holder)
        let total = session.selected.reduce(0) { $0 + session.dice[$1] }
        let sum = styledLabel("合计 \(total)", .title2)
        sum.textAlignment = .center
        let text = NSMutableAttributedString(string: "合计  ", attributes: [.font: UIFont.systemFont(ofSize: 18, weight: .semibold), .foregroundColor: Theme.ink])
        text.append(NSAttributedString(string: "\(total)", attributes: [.font: UIFont.systemFont(ofSize: 32, weight: .bold), .foregroundColor: Theme.coral]))
        sum.attributedText = text
        tray.content.addArrangedSubview(sum)
        let preview = try? session.preview()
        let hint = styledLabel(preview.map { "\($0.reason) · 获得 \($0.total) 分" } ?? "选择一个站点，点选骰子组合", .caption1)
        hint.textAlignment = .center
        tray.content.addArrangedSubview(hint)
        let budget = styledLabel("本局剩余重掷 \(session.player.rerolls) 次 · 连续精准 \(session.player.streak) 次", .caption2, .secondaryLabel)
        budget.textAlignment = .center
        tray.content.addArrangedSubview(budget)
        let reroll = button("重掷一颗 · 剩余\(session.player.rerolls)次") {
            let sheet = UIAlertController(title: "选择要重掷的骰子", message: "重掷后需要重新选择点数组合。", preferredStyle: .actionSheet)
            for index in self.session.dice.indices {
                sheet.addAction(UIAlertAction(title: "第 \(index + 1) 颗 · \(self.session.dice[index]) 点", style: .default) { _ in self.act(.reroll(index), revision: revision) })
            }
            sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
            sheet.popoverPresentationController?.sourceView = self.view
            self.present(sheet, animated: true)
        }
        reroll.isEnabled = session.player.rerolls > 0
        reroll.configuration?.baseForegroundColor = Theme.coral
        reroll.layer.borderColor = Theme.coral.cgColor
        reroll.layer.borderWidth = 0.8
        reroll.layer.cornerRadius = 24
        let confirm = button("确认到站", primary: true) { self.act(.confirm, revision: revision) }
        confirm.isEnabled = preview != nil
        for button in [reroll, confirm] {
            button.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { original in
                var result = original
                result.font = .systemFont(ofSize: 13, weight: .semibold)
                return result
            }
            button.configuration?.contentInsets = .init(top: 10, leading: 4, bottom: 10, trailing: 4)
            button.removeFromSuperview()
        }
        let actions = UIStackView(arrangedSubviews: [reroll, confirm])
        actions.distribution = .fillEqually
        actions.spacing = 8
        tray.content.addArrangedSubview(actions)
        stack.addArrangedSubview(tray)
    }

    func results() {
        label(session.trial ? "试玩完成" : "这一局，值得珍藏", style: .largeTitle)
        cover(session.definition.template)
        let best = session.players.map(\.score).max() ?? 0
        if session.players.count == 1 {
            label("本局 \(best) 分 · 精准 \(session.player.exactHits) 次", style: .title2)
            if !session.trial {
                let record =
                    Store.shared.library.personalBests[Library.bestKey(session.definition)] ?? best
                label("同规则个人最佳 · \(record) 分")
            }
        } else {
            let winners = session.players.filter { $0.score == best }.map(\.name)
            label(
                (winners.count > 1 ? "并列获胜：" : "获胜：") + winners.joined(separator: "、"),
                style: .title2)
        }
        for p in session.players { label("\(p.name)  ·  \(p.score) 分", style: .headline) }
        button("改成我的玩法") {
            self.push(EditorPage(definition: self.session.definition, copying: true))
        }
        button("回到游戏桌", primary: true) {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}

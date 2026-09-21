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
            self.definition.name = "My " + definition.template.title
            self.definition.imported = false
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Rule Workshop"
        stack.spacing = 12
        field("name", "Game name (1–40 characters)", definition.name, numeric: false)
        field("dice", "Six-sided dice (1–5)", "\(definition.rules.dice)")
        field("rounds", "Rounds per player (1–12)", "\(definition.rules.rounds)")
        if definition.template != .risk {
            field(
                "rerolls", definition.template == .station ? "Single-die rerolls per game (0–5)" : "Rerolls per round (0–5)",
                "\(definition.rules.rerolls)")
        }
        if definition.template == .station {
            field(
                "targets", "Target stops (comma-separated, one per round)",
                definition.rules.targets.map(String.init).joined(separator: ","), numeric: false)
            field("exact", "Exact-match points (1–10)", "\(definition.rules.exact)")
            field("near", "Off-by-one points (0–5)", "\(definition.rules.near)")
            field("streak", "Exact matches for a streak (2–6)", "\(definition.rules.streak)")
        }
        if definition.template != .risk {
            field(
                "bonus", definition.template == .station ? "Streak bonus (0–10)" : "Bonus per matching pair (0–10)",
                "\(definition.rules.bonus)")
        }
        if definition.template == .risk {
            field("riskFace", "Bust face (1–6)", "\(definition.rules.riskFace)")
            field("maxThrows", "Maximum rolls per round (2–8)", "\(definition.rules.maxThrows)")
        }
        let groups: [(String, String, String, [String])] = [
            ("Dice", "dice", "\(definition.rules.dice) six-sided dice", ["dice"]),
            ("Turn Actions", "hand.tap", definition.template == .risk ? "Roll again or bank" : "Select dice and reroll", ["rerolls", "riskFace", "maxThrows"]),
            ("Scoring", "star", definition.template == .station ? "Exact match +\(definition.rules.exact) pts" : (definition.template == .risk ? "Build a pot or bust" : "Dice total + pair bonus"), definition.template == .lucky ? ["bonus"] : ["exact", "near"]),
            ("Streak Bonus", "gift", definition.template == .station ? "Streak +\(definition.rules.bonus) pts" : "No extra bonus", definition.template == .station ? ["streak", "bonus"] : []),
            ("Game Length", "flag", "\(definition.rules.rounds) rounds", ["rounds", "targets"]),
        ]
        for (title, symbol, summary, keys) in groups {
            if title == "Streak Bonus" && definition.template != .station { continue }
            var cards = keys.compactMap { fieldCards[$0] }
            for card in cards { card.removeFromSuperview() }
            if cards.isEmpty {
                cards = [styledLabel(definition.template == .risk ? "Rolling the bust face scores zero for the round." : "Add all dice, then add the bonus for each matching pair.", .footnote)]
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
        let save = button("Save Game", primary: true) {
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
                self.message("Saved", "Saved to Workshop. Games already in progress keep their original rules.")
            } catch { self.error(error) }
        }
        save.removeFromSuperview()
        save.configuration = .plain()
        save.setTitle("Save", for: .normal)
        save.setTitleColor(Theme.coral, for: .normal)
        save.accessibilityLabel = "Save Game"
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: save)
        let trial = button("Playtest Rules", primary: true) {
            do {
                self.push(
                    PlayPage(
                        session: try Session(definition: self.read(), names: ["Player"], trial: true))
                )
            } catch { self.error(error) }
        }
        trial.configuration?.baseBackgroundColor = Theme.ink
        stack.addArrangedSubview(DicePageOrnament())
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
            text.backgroundColor = UIColor(red: 0.995, green: 0.982, blue: 0.950, alpha: 1)
            text.layer.borderWidth = 1
            text.layer.borderColor = Theme.ink.withAlphaComponent(0.22).cgColor
            text.tintColor = Theme.coral
            text.placeholder = "Game name in English"
            text.keyboardType = .asciiCapable
            text.autocorrectionType = .no
            text.addAction(UIAction { [weak text] _ in
                text?.text = EnglishText.input(text?.text ?? "")
            }, for: .editingChanged)
            text.clearButtonMode = .whileEditing
            text.addAction(UIAction { [weak text] _ in
                text?.layer.borderColor = Theme.coral.cgColor
            }, for: .editingDidBegin)
            text.addAction(UIAction { [weak text] _ in
                text?.layer.borderColor = Theme.ink.withAlphaComponent(0.22).cgColor
            }, for: .editingDidEnd)
            heading.text = "Game Name"
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
            guard let v = Int(field.text ?? "") else { throw RuleError.invalid("Enter a valid whole number.") }
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
            d.rules.targets = try text.replacingOccurrences(of: "\u{FF0C}", with: ",").components(
                separatedBy: ","
            ).map {
                guard let value = Int($0.trimmingCharacters(in: .whitespaces)) else {
                    throw RuleError.invalid("Enter whole numbers separated by commas.")
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
            ruleGroups["Dice"]?.setSummary("\(d.rules.dice) six-sided dice")
            ruleGroups["Game Length"]?.setSummary("\(d.rules.rounds) rounds")
            if d.template == .station {
                ruleGroups["Scoring"]?.setSummary("Exact match +\(d.rules.exact) pts")
                ruleGroups["Streak Bonus"]?.setSummary("\(d.rules.streak) matches: +\(d.rules.bonus) pts")
            }
            status.text = "✓ Rules ready\nYour game is ready to play."
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
    let count = UISegmentedControl(items: ["1", "2", "3", "4"])

    init(definition: Definition) {
        self.definition = definition
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Players"
        label(definition.name, style: .title1)
        label("Take turns on the same phone.", style: .subheadline)
        count.selectedSegmentIndex = 0
        stack.addArrangedSubview(count)
        for i in 0..<4 {
            let field = UITextField()
            field.text = "Player \(i + 1)"
            field.keyboardType = .asciiCapable
            field.autocorrectionType = .no
            field.addAction(UIAction { [weak field] _ in
                field?.text = EnglishText.input(field?.text ?? "")
            }, for: .editingChanged)
            field.font = .preferredFont(forTextStyle: .body)
            field.adjustsFontForContentSizeCategory = true
            field.borderStyle = .roundedRect
            field.inputAccessoryView = keyboardToolbar()
            field.accessibilityLabel = "Player \(i + 1) name"
            field.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
            names.append(field)
            stack.addArrangedSubview(field)
        }
        count.addAction(UIAction { [weak self] _ in self?.update() }, for: .valueChanged)
        update()
        button("Begin", primary: true) {
            if Store.shared.library.session != nil {
                self.confirm("Replace the current game?", message: "Only one game can be in progress. Starting a new game replaces it. Cancel to resume your current game from the game table.") {
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
            title: "Rules", style: .plain, target: self, action: #selector(rules))
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
                    UIAccessibility.post(notification: .announcement, argument: "Roll complete: " + self.session.dice.map { "\($0) pips" }.joined(separator: ", "))
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
        if session.trial { label("Rule playtest · Scores are not saved", style: .caption1, color: Theme.coral) }
        if session.phase == .finished {
            results()
            return
        }
        stack.spacing = 8
        let round = label("Round \(session.round) / \(session.definition.rules.rounds)", style: .caption1)
        round.textAlignment = .center
        playerBadges(session)
        if session.phase == .choosing && session.definition.template == .station
            && !traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            renderStationTable()
            return
        }
        if session.phase == .ready {
            cover(session.definition.template)
            label("Pass the phone to \(session.player.name), then roll when ready.")
            actionButton("Roll Dice", .roll, primary: true)
            return
        }
        if session.phase == .choosing && session.definition.template == .station {
            label("Choose a stop (✓ means scored)", style: .subheadline)
            let boardRevision = session.revision
            if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
                for target in session.definition.rules.targets {
                    if let score = session.player.stations[target] {
                        label("✓ Stop \(target) · \(score) pts")
                    } else {
                        actionButton(
                            "Stop \(target)", .target(target), primary: session.target == target)
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
            label("Points recorded\(session.trial ? " for this playtest" : " and saved").", style: .subheadline)
            actionButton(
                session.turn + 1 == session.players.count * session.definition.rules.rounds
                    ? "View Results" : "Next Turn", .next, primary: true)
            return
        }
        switch session.definition.template {
        case .station:
            label(
                "Select dice · Total \(session.selected.reduce(0) { $0 + session.dice[$1] })",
                style: .headline)
            if let preview = try? session.preview() {
                label("Preview: " + preview.explanation, color: Theme.coral)
            } else {
                label("Select dice and a stop to preview your score.", style: .footnote)
            }
            label(
                "Rerolls left: \(session.player.rerolls) · Streak: \(session.player.streak)",
                style: .footnote)
            if session.player.rerolls > 0 {
                let revision = session.revision
                button("Reroll One · \(session.player.rerolls) left") {
                    let sheet = UIAlertController(
                        title: "Choose a die to reroll", message: "Select your scoring dice again after rerolling.", preferredStyle: .actionSheet)
                    for i in self.session.dice.indices {
                        sheet.addAction(
                            UIAlertAction(
                                title: "Die \(i + 1) · \(self.session.dice[i]) pips", style: .default
                            ) { _ in self.act(.reroll(i), revision: revision) })
                    }
                    sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    sheet.popoverPresentationController?.sourceView = self.view
                    self.present(sheet, animated: true)
                }
            }
            let revision = session.revision
            let b = button("Confirm Stop", primary: true) { self.act(.confirm, revision: revision) }
            b.isEnabled = (try? session.preview()) != nil
            pinPrimary(b)
        case .lucky:
            label("Tap dice to keep them. All dice count toward your score.", style: .subheadline)
            label("Rerolls left this round: \(session.definition.rules.rerolls - session.turnRerolls)")
            if let score = try? session.preview() {
                label("Preview: " + score.explanation, color: Theme.coral)
            }
            if session.turnRerolls < session.definition.rules.rerolls
                && session.selected.count < session.dice.count
            {
                actionButton("Reroll Unkept Dice", .reroll(nil))
            }
            actionButton("Score Dice", .confirm, primary: true)
        case .risk:
            cover(.risk, height: 120)
            label("Pot · \(session.pot) pts", style: .largeTitle)
            label(
                "Roll \(session.throwCount) / \(session.definition.rules.maxThrows). Rolling a \(session.definition.rules.riskFace) busts this round."
            )
            actionButton("Bank Points", .confirm, primary: true)
            actionButton("Roll Again", .roll)
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
        let sum = styledLabel("Total \(total)", .title2)
        sum.textAlignment = .center
        let text = NSMutableAttributedString(string: "Total  ", attributes: [.font: UIFont.systemFont(ofSize: 18, weight: .semibold), .foregroundColor: Theme.ink])
        text.append(NSAttributedString(string: "\(total)", attributes: [.font: UIFont.systemFont(ofSize: 32, weight: .bold), .foregroundColor: Theme.coral]))
        sum.attributedText = text
        tray.content.addArrangedSubview(sum)
        let preview = try? session.preview()
        let hint = styledLabel(preview.map { "\($0.reason) · Earn \($0.total) pts" } ?? "Choose a stop and select dice", .caption1)
        hint.textAlignment = .center
        tray.content.addArrangedSubview(hint)
        let budget = styledLabel("Rerolls left: \(session.player.rerolls) · Streak: \(session.player.streak)", .caption2, .secondaryLabel)
        budget.textAlignment = .center
        tray.content.addArrangedSubview(budget)
        let reroll = button("Reroll One · \(session.player.rerolls) left") {
            let sheet = UIAlertController(title: "Choose a die to reroll", message: "Select your scoring dice again after rerolling.", preferredStyle: .actionSheet)
            for index in self.session.dice.indices {
                sheet.addAction(UIAlertAction(title: "Die \(index + 1) · \(self.session.dice[index]) pips", style: .default) { _ in self.act(.reroll(index), revision: revision) })
            }
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            sheet.popoverPresentationController?.sourceView = self.view
            self.present(sheet, animated: true)
        }
        reroll.isEnabled = session.player.rerolls > 0
        reroll.configuration?.baseForegroundColor = Theme.coral
        reroll.layer.borderColor = Theme.coral.cgColor
        reroll.layer.borderWidth = 0.8
        reroll.layer.cornerRadius = 24
        let confirm = button("Confirm Stop", primary: true) { self.act(.confirm, revision: revision) }
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
        label(session.trial ? "Playtest Complete" : "Game Complete", style: .largeTitle)
        cover(session.definition.template)
        let best = session.players.map(\.score).max() ?? 0
        if session.players.count == 1 {
            label(session.definition.template == .station
                ? "Score: \(best) pts · Exact matches: \(session.player.exactHits)"
                : "Score: \(best) pts", style: .title2)
            if !session.trial {
                let record =
                    Store.shared.library.personalBests[Library.bestKey(session.definition)] ?? best
                label("Personal best with these rules: \(record) pts")
            }
        } else {
            let winners = session.players.filter { $0.score == best }.map(\.name)
            label(
                (winners.count > 1 ? "Tied winners: " : "Winner: ") + winners.joined(separator: ", "),
                style: .title2)
        }
        for p in session.players { label("\(p.name)  ·  \(p.score) pts", style: .headline) }
        button("Make Your Own Version") {
            self.push(EditorPage(definition: self.session.definition, copying: true))
        }
        button("Back to Games", primary: true) {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}

import UIKit
import UniformTypeIdentifiers
import SafariServices

extension UTType {
    static let dicework = UTType(exportedAs: "com.cvcl.dicework", conformingTo: .json)
}
final class RootController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = Theme.ink
        viewControllers = ["Games", "Workshop", "Collection"].enumerated().map { i, title in
            let page = LibraryPage(mode: i)
            page.title = title
            let nav = UINavigationController(rootViewController: page)
            nav.navigationBar.prefersLargeTitles = false
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = Theme.paper
            appearance.shadowColor = .clear
            appearance.titleTextAttributes = [.foregroundColor: Theme.ink]
            nav.navigationBar.standardAppearance = appearance
            nav.navigationBar.scrollEdgeAppearance = appearance
            nav.navigationBar.tintColor = Theme.ink
            nav.tabBarItem = UITabBarItem(
                title: title,
                image: UIImage(
                    systemName: ["square.grid.2x2.fill", "wrench.and.screwdriver", "archivebox"][i]),
                tag: i)
            return nav
        }
        tabBar.backgroundColor = Theme.paper
        tabBar.tintColor = Theme.coral
    }

    func receive(_ url: URL) {
        selectedIndex = 1
        if let nav = selectedViewController as? UINavigationController {
            nav.popToRootViewController(animated: false)
            (nav.viewControllers.first as? LibraryPage)?.previewImport(url)
        }
    }
}
final class LibraryPage: Page, UIDocumentPickerDelegate {
    let mode: Int
    var showedWarning = false

    init(mode: Int) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        render()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !showedWarning, let warning = Store.shared.warning {
            showedWarning = true
            message("Data Recovery", warning)
        }
    }

    @objc func settings() { push(SettingsPage()) }
    func render() {
        clear()
        let library = Store.shared.library
        stack.spacing = mode == 0 ? 10 : 16
        let heading = label(["Games", "Rule Workshop", "Collection"][mode], style: .title1)
        heading.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: .systemFont(ofSize: 28, weight: .bold))
        let settingsButton = UIButton(type: .system)
        settingsButton.setImage(UIImage(systemName: "gearshape"), for: .normal)
        settingsButton.accessibilityLabel = "Settings"
        settingsButton.addAction(UIAction { [weak self] _ in self?.settings() }, for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        heading.addSubview(settingsButton)
        heading.isUserInteractionEnabled = true
        NSLayoutConstraint.activate([settingsButton.trailingAnchor.constraint(equalTo: heading.trailingAnchor), settingsButton.centerYAnchor.constraint(equalTo: heading.centerYAnchor), settingsButton.widthAnchor.constraint(equalToConstant: 44), settingsButton.heightAnchor.constraint(equalToConstant: 44)])
        if mode == 0 {
            let tagline = label("Good games start with your rules", style: .caption1)
            stack.setCustomSpacing(14, after: tagline)
            if let session = library.session {
                button(
                    "Resume Game · \(session.definition.name)\nRound \(session.round) · \(session.player.name)",
                    primary: true
                ) { self.push(PlayPage(session: session)) }
            }
            card(Definition.builtins[0])
            let pair = UIStackView()
            pair.spacing = 12
            pair.distribution = .fillEqually
            pair.axis =
                traitCollection.preferredContentSizeCategory.isAccessibilityCategory
                ? .vertical : .horizontal
            for d in Definition.builtins.dropFirst() {
                pair.addArrangedSubview(
                    GameCoverCard(d, compact: true) { self.push(DetailPage(definition: d)) })
            }
            stack.addArrangedSubview(pair)
            let create = button("+ Create a Game\nStart with a new rule") { self.tabBarController?.selectedIndex = 1 }
            create.configuration?.title = "Create a Game"
            create.configuration?.subtitle = "Start with a new rule"
            create.configuration?.image = UIImage(systemName: "plus.circle.fill")
            create.configuration?.imagePadding = 14
            create.configuration?.titleAlignment = .leading
            create.contentHorizontalAlignment = .leading
            create.configuration?.baseForegroundColor = Theme.coral
            create.layer.borderColor = Theme.coral.cgColor
            create.layer.borderWidth = 1
            create.layer.cornerRadius = 16
            if let recent = library.history.first {
                label("Recently Played", style: .headline)
                button(recent.definition.name) {
                    self.push(DetailPage(definition: recent.definition))
                }
            }
        } else if mode == 1 {
            label("Turn an idea into a tabletop game.", style: .subheadline)
            for d in Definition.builtins {
                let b = button("+ Create from \(d.name)") {
                    self.push(EditorPage(definition: d, copying: true))
                }
                b.configuration?.image = UIImage(systemName: d.template.symbol)
                b.configuration?.imagePadding = 14
                b.configuration?.subtitle = d.template.subtitle
                b.configuration?.titleAlignment = .leading
            }
            button("Import a .dicework File") { self.importPicker() }
            label("My Games · \(library.works.count)", style: .title2)
            if library.works.isEmpty {
                note("No games created yet\nChoose a game above, adjust its rules, and save.", symbol: "pencil.and.outline")
            }
            for d in library.works {
                button("\(d.name)  ›") { self.push(DetailPage(definition: d)) }
            }
        } else {
            label("Keep your favorites here.", style: .subheadline)
            let works = (Definition.builtins + library.works).filter {
                library.favorites.contains($0.id) || $0.imported
            }
            label("Saved Games", style: .title2)
            if works.isEmpty { note("No saved games yet. Favorite a game from its details or import one from a friend.", symbol: "books.vertical") }
            works.forEach { d in button(d.name) { self.push(DetailPage(definition: d)) } }
            button("Import a Game") { self.importPicker() }
            label("Game History · \(library.history.count)", style: .title2)
            if library.history.isEmpty {
                label("Completed games appear here. Rule playtests are not recorded.", color: .secondaryLabel)
            }
            library.history.forEach { s in
                button(
                    "\(s.definition.name) · \(s.created.formatted(.dateTime.month(.abbreviated).day().year().locale(Locale(identifier: "en_US"))))\n\(s.players.map { "\($0.name) \($0.score) pts" }.joined(separator: " / "))"
                ) { self.push(PlayPage(session: s)) }
            }
        }
        stack.addArrangedSubview(DicePageOrnament())
    }

    func card(_ d: Definition) {
        stack.addArrangedSubview(GameCoverCard(d) { self.push(DetailPage(definition: d)) })
    }

    func importPicker() {
        let p = UIDocumentPickerViewController(
            forOpeningContentTypes: [.dicework, .json], asCopy: true)
        p.delegate = self
        present(p, animated: true)
    }

    func documentPicker(
        _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]
    ) { if let url = urls.first { previewImport(url) } }

    func previewImport(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            let d = try Store.shared.importFile(url)
            push(ImportPage(definition: d))
        } catch { self.error(error) }
    }
}
final class DetailPage: Page {
    var definition: Definition

    init(definition: Definition) {
        self.definition = definition
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let saved = Store.shared.library.works.first(where: { $0.id == definition.id }) {
            definition = saved
        }
        render()
    }

    func render() {
        clear()
        title = "My Games"
        stack.spacing = 12
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), primaryAction: UIAction { [weak self] _ in self?.shareFile() })
        stack.addArrangedSubview(GameBoxCover(definition))
        let metadata = GameMetadataView()
        stack.addArrangedSubview(metadata)
        label("How to Play", style: .headline)
        let steps: [String]
        switch definition.template {
        case .station: steps = ["Roll the dice and choose a target stop", "Combine dice to match your target", "Play \(definition.rules.rounds) rounds. Highest score wins."]
        case .lucky: steps = ["Roll the dice and tap the ones to keep", "Reroll the rest to make matching pairs", "Play \(definition.rules.rounds) rounds and compare scores"]
        case .risk: steps = ["Roll dice to build your pot", "Roll again or bank. A bust scores zero.", "Play \(definition.rules.rounds) rounds and compare scores"]
        }
        for (index, text) in steps.enumerated() {
            let number = styledLabel("\(index + 1)", .caption1, .white)
            number.textAlignment = .center
            number.backgroundColor = Theme.coral
            number.layer.cornerRadius = 12
            number.clipsToBounds = true
            number.widthAnchor.constraint(equalToConstant: 24).isActive = true
            number.heightAnchor.constraint(equalToConstant: 24).isActive = true
            let row = UIStackView(arrangedSubviews: [number, styledLabel(text, .subheadline)])
            row.spacing = 10
            row.alignment = .center
            stack.addArrangedSubview(row)
        }
        button("Start Game", primary: true) { self.push(PlayersPage(definition: self.definition)) }
        let exists = Store.shared.library.works.contains { $0.id == definition.id }
        let edit = button(exists ? "Edit Rules" : "Customize") {
            self.push(EditorPage(definition: self.definition, copying: !exists))
        }
        let share = button("Share Game") { self.shareFile() }
        edit.removeFromSuperview(); share.removeFromSuperview()
        let actions = UIStackView(arrangedSubviews: [edit, share])
        actions.spacing = 10
        actions.distribution = .fillEqually
        stack.addArrangedSubview(actions)
        button("View Full Rules") { self.message("Full Rules", self.definition.summary) }
        button(Store.shared.library.favorites.contains(definition.id) ? "★ Favorited · Tap to Remove" : "☆ Favorite Game") {
            do {
                try Store.shared.commit {
                    if $0.favorites.contains(self.definition.id) {
                        $0.favorites.remove(self.definition.id)
                    } else {
                        $0.favorites.insert(self.definition.id)
                    }
                }
                self.render()
            } catch { self.error(error) }
        }
        button("Share Rules Image") { self.shareImage() }
        if exists {
            button("Delete Game") {
                self.confirm("Delete this game?", message: "Games in progress and past scores will not change.") {
                    do {
                        try Store.shared.commit {
                            $0.works.removeAll { $0.id == self.definition.id }
                            $0.favorites.remove(self.definition.id)
                        }
                        self.navigationController?.popViewController(animated: true)
                    } catch { self.error(error) }
                }
            }
        }
    }

    func share(_ item: Any) {
        let p = UIActivityViewController(activityItems: [item], applicationActivities: nil)
        p.popoverPresentationController?.sourceView = view
        present(p, animated: true)
    }

    func shareFile() {
        do {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(
                "Game-\(definition.id.uuidString).dicework")
            try JSONEncoder().encode(WorkFile(definition: definition)).write(
                to: url, options: .atomic)
            share(url)
        } catch { self.error(error) }
    }

    func shareImage() {
        let width: CGFloat = 900
        let text =
            definition.summary + "\n\n1–4 players · Pass and play · Highest score wins (ties allowed)\nThis image explains the rules. Use the .dicework file to import and play."
        let attr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 30), .foregroundColor: Theme.ink,
        ]
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 44), .foregroundColor: Theme.ink,
        ]
        let titleHeight = ceil(
            (definition.name as NSString).boundingRect(
                with: CGSize(width: width - 100, height: 1000),
                options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: titleAttributes,
                context: nil
            ).height)
        let bodyY = 410 + titleHeight
        let height =
            (text as NSString).boundingRect(
                with: CGSize(width: width - 100, height: 10000),
                options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attr, context: nil
            ).height + bodyY + 70
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height)).image { _ in
            Theme.paper.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: width, height: height))
            UIImage(named: definition.template.artwork)?.draw(
                in: CGRect(x: 0, y: 0, width: width, height: 330))
            (definition.name as NSString).draw(
                in: CGRect(x: 50, y: 360, width: width - 100, height: titleHeight + 4),
                withAttributes: titleAttributes)
            (text as NSString).draw(
                in: CGRect(x: 50, y: bodyY, width: width - 100, height: height - bodyY - 40),
                withAttributes: attr)
        }
        share(image)
    }
}
final class ImportPage: Page {
    let definition: Definition

    init(definition: Definition) {
        self.definition = definition
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Import Preview"
        label(definition.name, style: .title1)
        label(definition.summary)
        label("Valid game file. Importing saves a new copy without replacing existing games.", color: Theme.sage)
        button("Import Game", primary: true) {
            do {
                try Store.shared.commit { $0.works.append(self.definition) }
                self.navigationController?.popViewController(animated: true)
            } catch { self.error(error) }
        }
    }
}
final class SettingsPage: Page {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        label("Your games stay on your phone.", style: .title2)
        for (key, title) in [("haptics", "Dice Haptics"), ("sound", "Dice Sounds")] {
            let row = UIStackView()
            row.axis = .horizontal
            let name = UILabel()
            name.text = title
            name.textColor = Theme.ink
            let toggle = UISwitch()
            toggle.isOn = UserDefaults.standard.object(forKey: key) as? Bool ?? true
            toggle.addAction(
                UIAction { _ in UserDefaults.standard.set(toggle.isOn, forKey: key) },
                for: .valueChanged)
            row.addArrangedSubview(name)
            row.addArrangedSubview(toggle)
            stack.addArrangedSubview(row)
        }
        label("Supports Dynamic Type, VoiceOver, and Reduce Motion. No account or ads. All core gameplay works offline and is free.", style: .body)
        let privacyButton = button("Privacy Policy") { [weak self] in
            guard let self = self,
                let url = URL(string: "https://doc-hosting.flycricket.io/privacy-policy-for-rollweave/1ff1cb08-c5be-407e-9bd7-a1b48c112b81/privacy")
            else { return }
            let browser = SFSafariViewController(url: url)
            browser.preferredControlTintColor = Theme.ink
            self.present(browser, animated: true)
        }
        privacyButton.accessibilityIdentifier = "settings.privacyPolicy"
        privacyButton.accessibilityHint = "Opens the privacy policy webpage. An internet connection is required."
        button("Reload Local Data") {
            do {
                try Store.shared.reload()
                self.message("Data Reloaded", "Your local data has been reloaded.")
            } catch { self.error(error) }
        }
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        label("Rollweave: Slot Atelier \(version)\nGame files contain rules only, not players or scores. Deleting the app removes local data. Export your game files to back them up.", style: .footnote)
    }
}

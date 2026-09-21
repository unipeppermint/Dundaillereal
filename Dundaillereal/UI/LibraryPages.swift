import UIKit
import UniformTypeIdentifiers

extension UTType { static let dicework = UTType(exportedAs: "com.cvcl.dicework", conformingTo: .json) }
final class RootController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad(); view.tintColor = Theme.ink
        viewControllers = ["游戏桌", "工坊", "收藏柜"].enumerated().map { i, title in
            let page = LibraryPage(mode: i); page.title = title
            let nav = UINavigationController(rootViewController: page); nav.navigationBar.prefersLargeTitles = false
            let appearance = UINavigationBarAppearance(); appearance.configureWithOpaqueBackground(); appearance.backgroundColor = Theme.paper; appearance.shadowColor = .clear; appearance.titleTextAttributes = [.foregroundColor: Theme.ink]; nav.navigationBar.standardAppearance = appearance; nav.navigationBar.scrollEdgeAppearance = appearance; nav.navigationBar.tintColor = Theme.ink
            nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: ["square.grid.2x2.fill", "wrench.and.screwdriver", "archivebox"][i]), tag: i)
            return nav
        }
        tabBar.backgroundColor = Theme.paper; tabBar.tintColor = Theme.coral
    }
    func receive(_ url: URL) {
        selectedIndex = 1
        if let nav = selectedViewController as? UINavigationController { nav.popToRootViewController(animated: false); (nav.viewControllers.first as? LibraryPage)?.previewImport(url) }
    }
}
final class LibraryPage: Page, UIDocumentPickerDelegate {
    let mode: Int
    var showedWarning = false
    init(mode: Int) { self.mode = mode; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() { super.viewDidLoad(); navigationItem.title = "骰子工坊"; navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: self, action: #selector(settings)) }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); render() }
    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); if !showedWarning, let warning = Store.shared.warning { showedWarning = true; message("资料恢复提示", warning) } }
    @objc func settings() { push(SettingsPage()) }
    func render() {
        clear(); let library = Store.shared.library
        label(["游戏桌", "规则工坊", "收藏柜"][mode], style: .largeTitle)
        if mode == 0 {
            label("好玩的规则，由你创造", style: .subheadline)
            if let session = library.session { button("继续上局 · \(session.definition.name)\n第 \(session.round) 轮 · \(session.player.name)", primary: true) { self.push(PlayPage(session: session)) } }
            card(Definition.builtins[0])
            let pair = UIStackView(); pair.spacing = 12; pair.distribution = .fillEqually
            pair.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
            for d in Definition.builtins.dropFirst() { pair.addArrangedSubview(GameCoverCard(d, compact: true) { self.push(DetailPage(definition: d)) }) }
            stack.addArrangedSubview(pair)
            let create = button("＋ 创造你的玩法\n从一条新规则开始") { self.tabBarController?.selectedIndex = 1 }
            create.configuration?.baseForegroundColor = Theme.coral; create.layer.borderColor = Theme.coral.cgColor; create.layer.borderWidth = 1; create.layer.cornerRadius = 16
            if let recent = library.history.first { label("最近玩过", style: .headline); button(recent.definition.name) { self.push(DetailPage(definition: recent.definition)) } }
        } else if mode == 1 {
            label("把一个点子，变成一场桌游。", style: .subheadline)
            for d in Definition.builtins {
                let b = button("＋ 从《\(d.name)》新建") { self.push(EditorPage(definition: d, copying: true)) }
                b.configuration?.image = UIImage(systemName: d.template.symbol); b.configuration?.imagePadding = 14
                b.configuration?.subtitle = d.template.subtitle; b.configuration?.titleAlignment = .leading
            }
            button("导入 .dicework 玩法文件") { self.importPicker() }
            label("我的作品 · \(library.works.count)", style: .title2)
            if library.works.isEmpty { note("工坊还很安静\n选一个模板，改一条规则，就是你的第一份作品。", symbol: "pencil.and.outline") }
            for d in library.works { button("\(d.name)  ›") { self.push(DetailPage(definition: d)) } }
        } else {
            label("把好玩的，留在这里。", style: .subheadline)
            let works = (Definition.builtins + library.works).filter { library.favorites.contains($0.id) || $0.imported }
            label("收藏与导入", style: .title2)
            if works.isEmpty { note("还没有收藏。在作品详情点收藏，或导入朋友的玩法。", symbol: "books.vertical") }
            works.forEach { d in button(d.name) { self.push(DetailPage(definition: d)) } }
            button("导入朋友的玩法") { self.importPicker() }
            label("对局记录 · \(library.history.count)", style: .title2)
            if library.history.isEmpty { label("完成正式对局后，成绩会出现在这里。试玩不计入记录。", color: .secondaryLabel) }
            library.history.forEach { s in button("\(s.definition.name) · \(s.created.formatted(date: .abbreviated, time: .omitted))\n\(s.players.map { "\($0.name) \($0.score)分" }.joined(separator: " / "))") { self.push(PlayPage(session: s)) } }
        }
    }
    func card(_ d: Definition) { stack.addArrangedSubview(GameCoverCard(d) { self.push(DetailPage(definition: d)) }) }
    func importPicker() { let p = UIDocumentPickerViewController(forOpeningContentTypes: [.dicework, .json], asCopy: true); p.delegate = self; present(p, animated: true) }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { if let url = urls.first { previewImport(url) } }
    func previewImport(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
        do { let d = try Store.shared.importFile(url); push(ImportPage(definition: d)) } catch { self.error(error) }
    }
}
final class DetailPage: Page {
    var definition: Definition
    init(definition: Definition) { self.definition = definition; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); if let saved = Store.shared.library.works.first(where: { $0.id == definition.id }) { definition = saved }; render() }
    func render() {
        clear(); title = "玩法详情"
        stack.addArrangedSubview(GameCoverCard(definition))
        let heading = label("玩法说明", style: .title2)
        let summary = label(definition.summary)
        paperGroup([heading, summary])
        label("轮次结束后总分最高者获胜，可并列。单人挑战个人最佳。", style: .footnote)
        button("开始游戏", primary: true) { self.push(PlayersPage(definition: self.definition)) }
        let exists = Store.shared.library.works.contains { $0.id == definition.id }
        button(exists ? "编辑规则" : "复制并改编") { self.push(EditorPage(definition: self.definition, copying: !exists)) }
        button(Store.shared.library.favorites.contains(definition.id) ? "★ 已收藏 · 点击取消" : "☆ 收藏玩法") {
            do { try Store.shared.commit { if $0.favorites.contains(self.definition.id) { $0.favorites.remove(self.definition.id) } else { $0.favorites.insert(self.definition.id) } }; self.render() } catch { self.error(error) }
        }
        button("分享玩法文件") { self.shareFile() }; button("分享规则图片") { self.shareImage() }
        if exists { button("删除作品") { self.confirm("删除这份作品？", message: "已开始的对局和历史成绩不受影响。") { do { try Store.shared.commit { $0.works.removeAll { $0.id == self.definition.id }; $0.favorites.remove(self.definition.id) }; self.navigationController?.popViewController(animated: true) } catch { self.error(error) } } } }
    }
    func share(_ item: Any) { let p = UIActivityViewController(activityItems: [item], applicationActivities: nil); p.popoverPresentationController?.sourceView = view; present(p, animated: true) }
    func shareFile() {
        do { let url = FileManager.default.temporaryDirectory.appendingPathComponent("玩法-\(definition.id.uuidString).dicework"); try JSONEncoder().encode(WorkFile(definition: definition)).write(to: url, options: .atomic); share(url) } catch { self.error(error) }
    }
    func shareImage() {
        let width: CGFloat = 900; let text = definition.summary + "\n\n1–4 人 · 同机轮流 · 总分最高者获胜（可并列）\n图片为规则说明；导入游玩请使用 .dicework 文件。"
        let attr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 30), .foregroundColor: Theme.ink]
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 44), .foregroundColor: Theme.ink]
        let titleHeight = ceil((definition.name as NSString).boundingRect(with: CGSize(width: width - 100, height: 1000), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: titleAttributes, context: nil).height)
        let bodyY = 410 + titleHeight
        let height = (text as NSString).boundingRect(with: CGSize(width: width - 100, height: 10000), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attr, context: nil).height + bodyY + 70
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height)).image { _ in
            Theme.paper.setFill(); UIRectFill(CGRect(x: 0, y: 0, width: width, height: height))
            UIImage(named: definition.template.artwork)?.draw(in: CGRect(x: 0, y: 0, width: width, height: 330))
            (definition.name as NSString).draw(in: CGRect(x: 50, y: 360, width: width-100, height: titleHeight + 4), withAttributes: titleAttributes)
            (text as NSString).draw(in: CGRect(x: 50, y: bodyY, width: width-100, height: height-bodyY-40), withAttributes: attr)
        }; share(image)
    }
}
final class ImportPage: Page {
    let definition: Definition
    init(definition: Definition) { self.definition = definition; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() { super.viewDidLoad(); title = "导入预览"; label(definition.name, style: .title1); label(definition.summary); label("校验通过。将作为一份新作品保存，不覆盖已有作品。", color: Theme.sage); button("确认导入", primary: true) { do { try Store.shared.commit { $0.works.append(self.definition) }; self.navigationController?.popViewController(animated: true) } catch { self.error(error) } } }
}
final class SettingsPage: Page {
    override func viewDidLoad() {
        super.viewDidLoad(); title = "设置"; label("你的桌游，留在你的手机里。", style: .title2)
        for (key, title) in [("haptics", "投骰触感"), ("sound", "投骰声音")] {
            let row = UIStackView(); row.axis = .horizontal; let name = UILabel(); name.text = title; name.textColor = Theme.ink; let toggle = UISwitch(); toggle.isOn = UserDefaults.standard.object(forKey: key) as? Bool ?? true; toggle.addAction(UIAction { _ in UserDefaults.standard.set(toggle.isOn, forKey: key) }, for: .valueChanged); row.addArrangedSubview(name); row.addArrangedSubview(toggle); stack.addArrangedSubview(row)
        }
        label("支持系统大字体、旁白与减少动态效果。无账号、无广告、无网络服务。所有核心功能免费使用。", style: .body)
        button("重新载入本地资料") { do { try Store.shared.reload(); self.message("载入成功", "本地资料已恢复。") } catch { self.error(error) } }
        label("骰子工坊 1.0\n作品文件只包含规则，不包含玩家和成绩。卸载应用会移除本机资料，请通过分享玩法文件备份作品。", style: .footnote)
    }
}

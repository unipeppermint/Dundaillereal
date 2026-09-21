import UIKit

enum Theme {
    static let paper = UIColor(red: 0.969, green: 0.953, blue: 0.914, alpha: 1)
    static let ink = UIColor(red: 0.125, green: 0.208, blue: 0.290, alpha: 1)
    static let coral = UIColor(red: 0.929, green: 0.471, blue: 0.369, alpha: 1)
    static let sage = UIColor(red: 0.46, green: 0.56, blue: 0.46, alpha: 1)
}
class Page: UIViewController {
    let stack = UIStackView()
    let scroll = UIScrollView()
    private var pinned: UIView?
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = Theme.paper
        scroll.keyboardDismissMode = .interactive; scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll); stack.axis = .vertical; stack.spacing = 16; stack.translatesAutoresizingMaskIntoConstraints = false; scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor), scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor), scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 18), stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -28), stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 22), stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -22), stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -44)
        ])
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent { clear() }
    }
    @objc func dismissKeyboard() { view.endEditing(true) }
    func keyboardToolbar() -> UIToolbar { let bar = UIToolbar(); bar.items = [UIBarButtonItem(systemItem: .flexibleSpace), UIBarButtonItem(title: "完成输入", style: .done, target: self, action: #selector(dismissKeyboard))]; bar.sizeToFit(); return bar }
    func clear() { pinned?.removeFromSuperview(); pinned = nil; scroll.contentInset.bottom = 0; stack.arrangedSubviews.forEach { $0.removeFromSuperview() } }
    func pinPrimary(_ button: UIButton) {
        button.removeFromSuperview()
        let bar = UIView(); bar.backgroundColor = Theme.paper; bar.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false; bar.addSubview(button); view.addSubview(bar); pinned = bar
        NSLayoutConstraint.activate([bar.leadingAnchor.constraint(equalTo: view.leadingAnchor), bar.trailingAnchor.constraint(equalTo: view.trailingAnchor), bar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor), button.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 22), button.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -22), button.topAnchor.constraint(equalTo: bar.topAnchor, constant: 10), button.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -10)])
        scroll.contentInset.bottom = 84
    }
    override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); if let pinned { scroll.contentInset.bottom = pinned.bounds.height + 12 } }
    @discardableResult func label(_ text: String, style: UIFont.TextStyle = .body, color: UIColor = Theme.ink) -> UILabel {
        let v = UILabel(); v.text = text; v.numberOfLines = 0; v.font = .preferredFont(forTextStyle: style); v.adjustsFontForContentSizeCategory = true; v.textColor = color; stack.addArrangedSubview(v); return v
    }
    @discardableResult func button(_ title: String, primary: Bool = false, action: @escaping () -> Void) -> UIButton {
        let b = UIButton(type: .system); var c = UIButton.Configuration.filled(); c.title = title; c.baseBackgroundColor = primary ? Theme.coral : UIColor(red: 0.995, green: 0.982, blue: 0.950, alpha: 1); c.baseForegroundColor = primary ? .white : Theme.ink; c.cornerStyle = .large; c.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16); b.configuration = c; b.layer.shadowColor = Theme.ink.cgColor; b.layer.shadowOpacity = 0.08; b.layer.shadowOffset = CGSize(width: 0, height: 3); b.layer.shadowRadius = 5; b.titleLabel?.numberOfLines = 0; b.addAction(UIAction { _ in action() }, for: .touchUpInside); stack.addArrangedSubview(b); b.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true; return b
    }
    func error(_ error: Error) { message("未能完成", error.localizedDescription) }
    func message(_ title: String, _ text: String) { let a = UIAlertController(title: title, message: text, preferredStyle: .alert); a.addAction(UIAlertAction(title: "知道了", style: .default)); present(a, animated: true) }
    func push(_ page: UIViewController) { navigationController?.pushViewController(page, animated: true) }
    func confirm(_ title: String, message: String, action: @escaping () -> Void) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert); a.addAction(UIAlertAction(title: "取消", style: .cancel)); a.addAction(UIAlertAction(title: "确认", style: .destructive) { _ in action() }); present(a, animated: true)
    }
    func cover(_ template: Template, height: CGFloat = 170) { let v = ArtworkView(template.artwork); v.layer.cornerRadius = 20; v.heightAnchor.constraint(equalToConstant: height).isActive = true; stack.addArrangedSubview(v) }
}
final class DiceButton: UIButton {
    let value: Int
    private let picked: Bool
    init(value: Int, selected: Bool, action: @escaping () -> Void) {
        self.value = value; self.picked = selected; super.init(frame: .zero); backgroundColor = .clear; isOpaque = false
        layer.cornerRadius = 13; layer.borderWidth = selected ? 3 : 1; layer.borderColor = (selected ? Theme.coral : Theme.ink.withAlphaComponent(0.15)).cgColor
        layer.shadowColor = Theme.ink.cgColor; layer.shadowOpacity = 0.22; layer.shadowRadius = 5; layer.shadowOffset = CGSize(width: 1, height: 5)
        heightAnchor.constraint(equalTo: widthAnchor).isActive = true
        accessibilityLabel = "\(value) 点"; accessibilityValue = selected ? "已选择" : "未选择"; addAction(UIAction { _ in action() }, for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            context.saveGState(); UIBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), cornerRadius: 13).addClip()
            let colors = [UIColor.white.cgColor, (picked ? UIColor(red: 1, green: 0.83, blue: 0.66, alpha: 1) : UIColor(red: 0.94, green: 0.9, blue: 0.77, alpha: 1)).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0,1]) { context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: rect.width, y: rect.height), options: []) }; context.restoreGState()
        }
        let positions: [(CGFloat,CGFloat)]
        switch value {
        case 1: positions = [(0.5,0.5)]
        case 2: positions = [(0.28,0.28),(0.72,0.72)]
        case 3: positions = [(0.28,0.28),(0.5,0.5),(0.72,0.72)]
        case 4: positions = [(0.28,0.28),(0.72,0.28),(0.28,0.72),(0.72,0.72)]
        case 5: positions = [(0.28,0.28),(0.72,0.28),(0.5,0.5),(0.28,0.72),(0.72,0.72)]
        default: positions = [(0.28,0.25),(0.72,0.25),(0.28,0.5),(0.72,0.5),(0.28,0.75),(0.72,0.75)]
        }
        UIColor.white.withAlphaComponent(0.55).setStroke(); let rim = UIBezierPath(roundedRect: rect.insetBy(dx: 4, dy: 4), cornerRadius: 10); rim.lineWidth = 2; rim.stroke()
        Theme.ink.setFill(); let d = rect.width * 0.13
        for (x,y) in positions { UIBezierPath(ovalIn: CGRect(x: x * rect.width - d / 2, y: y * rect.height - d / 2, width: d, height: d)).fill() }
    }
}

final class RouteBoard: UIView {
    private var buttons: [UIButton] = []
    private let art = ArtworkView("BoardArt")
    private let track = CAShapeLayer()
    private let sleepers = CAShapeLayer()
    init(targets: [Int], scores: [Int: Int], selected: Int?, action: @escaping (Int) -> Void) {
        super.init(frame: .zero); layer.cornerRadius = 22; clipsToBounds = true
        addSubview(art); layer.addSublayer(track); layer.addSublayer(sleepers)
        track.strokeColor = Theme.ink.withAlphaComponent(0.8).cgColor; track.fillColor = UIColor.clear.cgColor; track.lineWidth = 9; track.lineCap = .round
        sleepers.strokeColor = Theme.paper.cgColor; sleepers.fillColor = UIColor.clear.cgColor; sleepers.lineWidth = 1.5; sleepers.lineDashPattern = [4,5]
        heightAnchor.constraint(equalToConstant: max(260, CGFloat((targets.count + 1) / 2) * 74 + 30)).isActive = true
        for target in targets {
            let b = UIButton(type: .system); b.titleLabel?.font = .preferredFont(forTextStyle: .headline); b.titleLabel?.numberOfLines = 2
            b.setTitle(scores[target].map { "✓ \(target)\n\($0)分" } ?? "\(target)", for: .normal)
            b.setTitleColor(selected == target ? .white : Theme.ink, for: .normal)
            b.backgroundColor = selected == target ? Theme.coral : (scores[target] != nil ? UIColor(red: 0.8, green: 0.85, blue: 0.77, alpha: 1) : Theme.paper)
            b.layer.cornerRadius = 26; b.layer.borderWidth = 2.5; b.layer.borderColor = (selected == target ? Theme.paper : Theme.ink).cgColor
            b.layer.shadowColor = Theme.ink.cgColor; b.layer.shadowOpacity = 0.25; b.layer.shadowOffset = CGSize(width: 0, height: 3); b.layer.shadowRadius = 3
            b.accessibilityLabel = "站点 \(target)"; b.accessibilityValue = scores[target].map { "已填写，\($0)分" } ?? (selected == target ? "已选择" : "未填写")
            b.accessibilityIdentifier = "station-\(target)"; b.isEnabled = scores[target] == nil; b.addAction(UIAction { _ in action(target) }, for: .touchUpInside); addSubview(b); buttons.append(b)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews(); art.frame = bounds
        let rows = max(1, (buttons.count + 1) / 2)
        for (i,b) in buttons.enumerated() {
            let row = i / 2; let col = row % 2 == 0 ? i % 2 : 1 - i % 2
            let x = bounds.width * (col == 0 ? 0.28 : 0.72)
            let y = bounds.height - 48 - CGFloat(row) * (bounds.height - 96) / CGFloat(max(1, rows - 1)) - (i % 2 == 1 ? 18 : 0)
            b.frame = CGRect(x: x - 26, y: y - 26, width: 52, height: 52)
        }
        let path = UIBezierPath()
        for (i,b) in buttons.enumerated() {
            if i == 0 { path.move(to: b.center) }
            else { let a = buttons[i-1].center; let midY = (a.y + b.center.y) / 2
                if abs(a.x - b.center.x) < 20 {
                    let bend: CGFloat = a.x > bounds.midX ? 62 : -62
                    path.addCurve(to: b.center, controlPoint1: CGPoint(x: a.x + bend, y: a.y - 25), controlPoint2: CGPoint(x: b.center.x + bend, y: b.center.y + 25))
                } else { path.addCurve(to: b.center, controlPoint1: CGPoint(x: a.x, y: midY - 36), controlPoint2: CGPoint(x: b.center.x, y: midY + 36)) } }
        }
        track.path = path.cgPath; sleepers.path = path.cgPath
    }
}

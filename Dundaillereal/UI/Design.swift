import UIKit

enum Theme {
    static let paper = UIColor(red: 0.969, green: 0.953, blue: 0.914, alpha: 1)
    static let ink = UIColor(red: 0.125, green: 0.208, blue: 0.290, alpha: 1)
    static let coral = UIColor(red: 0.929, green: 0.471, blue: 0.369, alpha: 1)
    static let sage = UIColor(red: 0.46, green: 0.56, blue: 0.46, alpha: 1)
}
class Page: UIViewController {
    let stack = UIStackView()
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = Theme.paper
        let scroll = UIScrollView(); scroll.keyboardDismissMode = .interactive; scroll.translatesAutoresizingMaskIntoConstraints = false
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
    func clear() { stack.arrangedSubviews.forEach { $0.removeFromSuperview() } }
    @discardableResult func label(_ text: String, style: UIFont.TextStyle = .body, color: UIColor = Theme.ink) -> UILabel {
        let v = UILabel(); v.text = text; v.numberOfLines = 0; v.font = .preferredFont(forTextStyle: style); v.adjustsFontForContentSizeCategory = true; v.textColor = color; stack.addArrangedSubview(v); return v
    }
    @discardableResult func button(_ title: String, primary: Bool = false, action: @escaping () -> Void) -> UIButton {
        let b = UIButton(type: .system); var c = UIButton.Configuration.filled(); c.title = title; c.baseBackgroundColor = primary ? Theme.ink : .white.withAlphaComponent(0.7); c.baseForegroundColor = primary ? .white : Theme.ink; c.cornerStyle = .large; c.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16); b.configuration = c; b.titleLabel?.numberOfLines = 0; b.addAction(UIAction { _ in action() }, for: .touchUpInside); stack.addArrangedSubview(b); b.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true; return b
    }
    func error(_ error: Error) { message("未能完成", error.localizedDescription) }
    func message(_ title: String, _ text: String) { let a = UIAlertController(title: title, message: text, preferredStyle: .alert); a.addAction(UIAlertAction(title: "知道了", style: .default)); present(a, animated: true) }
    func push(_ page: UIViewController) { navigationController?.pushViewController(page, animated: true) }
    func confirm(_ title: String, message: String, action: @escaping () -> Void) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert); a.addAction(UIAlertAction(title: "取消", style: .cancel)); a.addAction(UIAlertAction(title: "确认", style: .destructive) { _ in action() }); present(a, animated: true)
    }
    func cover(_ template: Template, height: CGFloat = 170) { let v = LandscapeView(); v.template = template; v.heightAnchor.constraint(equalToConstant: height).isActive = true; stack.addArrangedSubview(v) }
}
/// Decorative landscape is independent of all live game state and hit targets.
final class LandscapeView: UIView {
    var template = Template.station
    override func draw(_ rect: CGRect) {
        guard let c = UIGraphicsGetCurrentContext() else { return }
        Theme.paper.setFill(); UIRectFill(rect); UIBezierPath(roundedRect: rect, cornerRadius: 24).fill()
        c.saveGState(); UIBezierPath(roundedRect: rect, cornerRadius: 24).addClip()
        for layer in 0..<3 {
            let p = UIBezierPath(); p.move(to: CGPoint(x: 0, y: rect.height))
            for i in 0...12 { let x = CGFloat(i) * rect.width / 12; let y = rect.height * (0.3 + CGFloat(layer) * 0.18) + sin(CGFloat(i) * 1.8 + CGFloat(layer)) * 25; p.addLine(to: CGPoint(x: x, y: y)) }
            p.addLine(to: CGPoint(x: rect.width, y: rect.height)); p.close(); Theme.sage.withAlphaComponent(0.15 + CGFloat(layer) * 0.08).setFill(); p.fill()
        }
        let route = UIBezierPath(); route.move(to: CGPoint(x: 0, y: rect.height * 0.85)); route.addCurve(to: CGPoint(x: rect.width, y: rect.height * 0.5), controlPoint1: CGPoint(x: rect.width * 0.85, y: rect.height), controlPoint2: CGPoint(x: rect.width * 0.1, y: rect.height * 0.15)); route.lineWidth = 12; Theme.ink.withAlphaComponent(0.65).setStroke(); route.stroke(); route.lineWidth = 1.5; route.setLineDash([6,6], count: 2, phase: 0); Theme.paper.setStroke(); route.stroke()
        let image = UIImage(systemName: template.symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 45, weight: .regular))?.withTintColor(Theme.coral, renderingMode: .alwaysOriginal); image?.draw(in: CGRect(x: rect.width * 0.62, y: 30, width: 55, height: 55)); c.restoreGState()
    }
}
final class DiceButton: UIButton {
    let value: Int
    init(value: Int, selected: Bool, action: @escaping () -> Void) {
        self.value = value; super.init(frame: .zero); backgroundColor = selected ? Theme.coral.withAlphaComponent(0.18) : .white
        layer.cornerRadius = 13; layer.borderWidth = selected ? 3 : 1; layer.borderColor = (selected ? Theme.coral : Theme.ink.withAlphaComponent(0.15)).cgColor
        heightAnchor.constraint(equalTo: widthAnchor).isActive = true
        accessibilityLabel = "\(value) 点"; accessibilityValue = selected ? "已选择" : "未选择"; addAction(UIAction { _ in action() }, for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func draw(_ rect: CGRect) {
        let positions: [(CGFloat,CGFloat)]
        switch value {
        case 1: positions = [(0.5,0.5)]
        case 2: positions = [(0.28,0.28),(0.72,0.72)]
        case 3: positions = [(0.28,0.28),(0.5,0.5),(0.72,0.72)]
        case 4: positions = [(0.28,0.28),(0.72,0.28),(0.28,0.72),(0.72,0.72)]
        case 5: positions = [(0.28,0.28),(0.72,0.28),(0.5,0.5),(0.28,0.72),(0.72,0.72)]
        default: positions = [(0.28,0.25),(0.72,0.25),(0.28,0.5),(0.72,0.5),(0.28,0.75),(0.72,0.75)]
        }
        Theme.ink.setFill(); let d = rect.width * 0.13
        for (x,y) in positions { UIBezierPath(ovalIn: CGRect(x: x * rect.width - d / 2, y: y * rect.height - d / 2, width: d, height: d)).fill() }
    }
}

final class RouteBoard: UIView {
    private let targets: [Int]
    private var buttons: [UIButton] = []
    init(targets: [Int], scores: [Int: Int], selected: Int?, action: @escaping (Int) -> Void) {
        self.targets = targets; super.init(frame: .zero); backgroundColor = Theme.sage.withAlphaComponent(0.09); layer.cornerRadius = 22
        heightAnchor.constraint(equalToConstant: CGFloat((targets.count + 1) / 2) * 82 + 24).isActive = true
        for target in targets {
            let b = UIButton(type: .system); b.titleLabel?.font = .preferredFont(forTextStyle: .headline); b.titleLabel?.adjustsFontForContentSizeCategory = true; b.titleLabel?.numberOfLines = 2
            b.setTitle(scores[target].map { "✓ \(target)\n\($0)分" } ?? "\(target)", for: .normal)
            b.setTitleColor(selected == target ? .white : Theme.ink, for: .normal)
            b.backgroundColor = selected == target ? Theme.coral : (scores[target] != nil ? UIColor(red: 0.8, green: 0.85, blue: 0.77, alpha: 1) : Theme.paper)
            b.layer.cornerRadius = 22; b.layer.borderWidth = 2; b.layer.borderColor = Theme.ink.withAlphaComponent(0.5).cgColor
            b.accessibilityLabel = "站点 \(target)"; b.accessibilityValue = scores[target].map { "已填写，\($0)分" } ?? (selected == target ? "已选择" : "未填写")
            b.accessibilityIdentifier = "station-\(target)"; b.isEnabled = scores[target] == nil; b.addAction(UIAction { _ in action(target) }, for: .touchUpInside); addSubview(b); buttons.append(b)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        for (i,b) in buttons.enumerated() { let row = i / 2; let col = row % 2 == 0 ? i % 2 : 1 - i % 2; b.frame = CGRect(x: col == 0 ? 24 : bounds.width - 104, y: 12 + CGFloat(row) * 82, width: 80, height: 66) }; setNeedsDisplay()
    }
    override func draw(_ rect: CGRect) {
        let p = UIBezierPath(); for (i,b) in buttons.enumerated() { if i == 0 { p.move(to: b.center) } else { p.addLine(to: b.center) } }; Theme.ink.withAlphaComponent(0.4).setStroke(); p.lineWidth = 5; p.stroke()
    }
}

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
        super.viewDidLoad()
        view.backgroundColor = Theme.paper
        scroll.keyboardDismissMode = .interactive
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(
                equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -28),
            stack.leadingAnchor.constraint(
                equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(
                equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -22),
            stack.widthAnchor.constraint(
                equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -44),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationItem.backButtonDisplayMode = .minimal
        if navigationController?.viewControllers.first !== self {
            let back = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backToPrevious))
            back.accessibilityLabel = "Back"
            if #available(iOS 26.0, *) { back.hidesSharedBackground = true }
            navigationItem.leftBarButtonItem = back
        }
    }

    @objc private func backToPrevious() { navigationController?.popViewController(animated: true) }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent { clear() }
    }

    @objc func dismissKeyboard() { view.endEditing(true) }
    func keyboardToolbar() -> UIToolbar {
        let bar = UIToolbar()
        bar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(
                title: "Done", style: .done, target: self, action: #selector(dismissKeyboard)),
        ]
        bar.sizeToFit()
        return bar
    }

    func clear() {
        pinned?.removeFromSuperview()
        pinned = nil
        scroll.contentInset.bottom = 0
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    func pinPrimary(_ button: UIButton) {
        button.removeFromSuperview()
        let bar = UIView()
        bar.backgroundColor = Theme.paper
        bar.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(button)
        view.addSubview(bar)
        pinned = bar
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 22),
            button.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -22),
            button.topAnchor.constraint(equalTo: bar.topAnchor, constant: 10),
            button.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -10),
        ])
        scroll.contentInset.bottom = 84
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let pinned { scroll.contentInset.bottom = pinned.bounds.height + 12 }
        if #available(iOS 26.0, *) {
            navigationItem.rightBarButtonItems?.forEach { $0.hidesSharedBackground = true }
        }
    }

    @discardableResult func label(
        _ text: String, style: UIFont.TextStyle = .body, color: UIColor = Theme.ink
    ) -> UILabel {
        let v = UILabel()
        v.text = text
        v.numberOfLines = 0
        v.font = .preferredFont(forTextStyle: style)
        v.adjustsFontForContentSizeCategory = true
        v.textColor = color
        stack.addArrangedSubview(v)
        return v
    }

    @discardableResult func button(
        _ title: String, primary: Bool = false, action: @escaping () -> Void
    ) -> UIButton {
        let b = UIButton(type: .system)
        var c = UIButton.Configuration.filled()
        c.title = title
        c.baseBackgroundColor =
            primary ? Theme.coral : UIColor(red: 0.995, green: 0.982, blue: 0.950, alpha: 1)
        c.baseForegroundColor = primary ? .white : Theme.ink
        c.cornerStyle = .capsule
        c.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        b.configuration = c
        b.layer.shadowColor = Theme.ink.cgColor
        b.layer.shadowOpacity = 0.08
        b.layer.shadowOffset = CGSize(width: 0, height: 3)
        b.layer.shadowRadius = 5
        b.titleLabel?.numberOfLines = 0
        b.addAction(UIAction { _ in action() }, for: .touchUpInside)
        stack.addArrangedSubview(b)
        b.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        return b
    }

    func error(_ error: Error) {
        let detail = error.localizedDescription
        message("Unable to Complete", EnglishText.containsHan(detail)
            ? "The operation could not be completed. Please try again." : detail)
    }

    func message(_ title: String, _ text: String) {
        let a = UIAlertController(title: title, message: text, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    func push(_ page: UIViewController) {
        page.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(page, animated: true)
    }

    func confirm(_ title: String, message: String, action: @escaping () -> Void) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        a.addAction(UIAlertAction(title: "Confirm", style: .destructive) { _ in action() })
        present(a, animated: true)
    }

    func cover(_ template: Template, height: CGFloat = 170) {
        let v = ArtworkView(template.artwork)
        v.layer.cornerRadius = 20
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        stack.addArrangedSubview(v)
    }
}
final class DiceButton: UIButton {
    let value: Int
    private let artwork = UIImageView()

    init(value: Int, selected: Bool, action: @escaping () -> Void) {
        self.value = value
        super.init(frame: .zero)
        backgroundColor = .clear
        artwork.image = ResultDieRenderer.image(value: value)
        artwork.contentMode = .scaleAspectFit
        artwork.isUserInteractionEnabled = false
        artwork.layer.shadowColor = UIColor(red: 0.32, green: 0.26, blue: 0.17, alpha: 1).cgColor
        artwork.layer.shadowOpacity = 0.20
        artwork.layer.shadowRadius = 4
        artwork.layer.shadowOffset = CGSize(width: 1, height: 4)
        addSubview(artwork)
        layer.cornerRadius = 18
        layer.borderWidth = selected ? 1.5 : 0
        layer.borderColor = Theme.coral.withAlphaComponent(0.8).cgColor
        if selected { backgroundColor = Theme.coral.withAlphaComponent(0.08) }
        heightAnchor.constraint(equalTo: widthAnchor).isActive = true
        accessibilityLabel = "\(value) pips"
        accessibilityValue = selected ? "Selected" : "Not selected"
        if selected { accessibilityTraits.insert(.selected) }
        addAction(UIAction { _ in action() }, for: .touchUpInside)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        artwork.frame = bounds.insetBy(dx: 1, dy: 1).offsetBy(dx: 0, dy: -3)
    }

    override var isHighlighted: Bool {
        didSet { artwork.transform = isHighlighted ? CGAffineTransform(scaleX: 0.94, y: 0.94) : .identity }
    }

    required init?(coder: NSCoder) { fatalError() }
}

final class RouteBoard: UIView {
    private var buttons: [UIButton] = []
    private let art = ArtworkView("BoardArt")
    private let track = CAShapeLayer()
    private let sleepers = CAShapeLayer()

    init(targets: [Int], scores: [Int: Int], selected: Int?, height: CGFloat? = nil, action: @escaping (Int) -> Void) {
        super.init(frame: .zero)
        layer.cornerRadius = 22
        clipsToBounds = true
        addSubview(art)
        layer.addSublayer(track)
        layer.addSublayer(sleepers)
        track.strokeColor = Theme.ink.withAlphaComponent(0.8).cgColor
        track.fillColor = UIColor.clear.cgColor
        track.lineWidth = 11
        track.lineCap = .round
        sleepers.strokeColor = Theme.paper.cgColor
        sleepers.fillColor = UIColor.clear.cgColor
        sleepers.lineWidth = 1.5
        sleepers.lineDashPattern = [4, 5]
        heightAnchor.constraint(
            equalToConstant: max(height ?? 260, CGFloat(targets.count) * 36)
        ).isActive = true
        for target in targets {
            let b = UIButton(type: .system)
            b.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
            b.titleLabel?.numberOfLines = 2
            b.titleLabel?.textAlignment = .center
            b.titleLabel?.adjustsFontSizeToFitWidth = true
            b.titleLabel?.minimumScaleFactor = 0.8
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineSpacing = 1
            let title = NSMutableAttributedString(string: "\(target)", attributes: [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .paragraphStyle: paragraph,
                .foregroundColor: selected == target ? UIColor.white : Theme.ink,
            ])
            if let score = scores[target] {
                title.append(NSAttributedString(string: "\n\(score) pts", attributes: [
                    .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                    .paragraphStyle: paragraph,
                    .foregroundColor: Theme.ink,
                ]))
            }
            b.setAttributedTitle(title, for: .normal)
            b.setTitleColor(selected == target ? .white : Theme.ink, for: .normal)
            b.backgroundColor =
                selected == target
                ? Theme.coral
                : (scores[target] != nil
                    ? UIColor(red: 0.8, green: 0.85, blue: 0.77, alpha: 1) : Theme.paper)
            b.layer.cornerRadius = 26
            b.layer.borderWidth = 1.5
            b.layer.borderColor = (selected == target ? Theme.paper : Theme.ink).cgColor
            b.layer.shadowColor = Theme.ink.cgColor
            b.layer.shadowOpacity = 0.25
            b.layer.shadowOffset = CGSize(width: 0, height: 3)
            b.layer.shadowRadius = 3
            b.accessibilityLabel = "Stop \(target)"
            b.accessibilityValue =
                scores[target].map { "Scored, \($0) pts" } ?? (selected == target ? "Selected" : "Empty")
            b.accessibilityIdentifier = "station-\(target)"
            b.isUserInteractionEnabled = scores[target] == nil
            b.addAction(UIAction { _ in action(target) }, for: .touchUpInside)
            addSubview(b)
            buttons.append(b)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        art.frame = bounds
        // Trace the painted road in the image's normalized coordinates. Apply the
        // same aspect-fill transform as ArtworkView, including its crop offset.
        guard let image = art.image else { return }
        let scale = max(bounds.width / image.size.width, bounds.height / image.size.height)
        let rendered = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: (bounds.width - rendered.width) / 2 + x * rendered.width,
                    y: (bounds.height - rendered.height) / 2 + y * rendered.height)
        }
        let segments: [[CGPoint]] = [
            [point(0.30, 0.98), point(0.24, 0.91), point(0.59, 0.87), point(0.37, 0.77)],
            [point(0.37, 0.77), point(0.02, 0.67), point(0.34, 0.62), point(0.61, 0.58)],
            [point(0.61, 0.58), point(0.96, 0.51), point(0.45, 0.49), point(0.49, 0.42)],
            [point(0.49, 0.42), point(0.51, 0.36), point(1.02, 0.33), point(0.71, 0.27)],
            [point(0.71, 0.27), point(0.60, 0.24), point(0.63, 0.24), point(0.74, 0.22)],
        ]
        let path = UIBezierPath()
        path.move(to: segments[0][0])
        var samples: [CGPoint] = []
        let safe = bounds.insetBy(dx: 29, dy: 29)
        for segment in segments {
            path.addCurve(to: segment[3], controlPoint1: segment[1], controlPoint2: segment[2])
            for step in 0...100 {
                let t = CGFloat(step) / 100, u = 1 - t
                let p = CGPoint(
                    x: u*u*u*segment[0].x + 3*u*u*t*segment[1].x + 3*u*t*t*segment[2].x + t*t*t*segment[3].x,
                    y: u*u*u*segment[0].y + 3*u*u*t*segment[1].y + 3*u*t*t*segment[2].y + t*t*t*segment[3].y)
                if safe.contains(p) { samples.append(p) }
            }
        }
        track.path = path.cgPath
        sleepers.path = path.cgPath
        guard let first = samples.first else { return }
        var lengths: [CGFloat] = [0]
        for index in 1..<samples.count {
            lengths.append(lengths[index - 1] + hypot(samples[index].x - samples[index - 1].x,
                                                     samples[index].y - samples[index - 1].y))
        }
        let total = lengths.last ?? 0
        for (index, button) in buttons.enumerated() {
            let distance = total * (buttons.count == 1 ? 0.5 : CGFloat(index) / CGFloat(buttons.count - 1))
            let sampleIndex = lengths.firstIndex(where: { $0 >= distance }) ?? 0
            let center = samples.isEmpty ? first : samples[sampleIndex]
            button.frame = CGRect(x: center.x - 26, y: center.y - 26, width: 52, height: 52)
        }
    }
}

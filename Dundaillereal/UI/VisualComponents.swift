import UIKit

extension Template {
    var artwork: String {
        switch self {
        case .station: return "StationArt"
        case .lucky: return "LuckyArt"
        case .risk: return "RiskArt"
        }
    }
}

/// Decoration never contains live points, scores or hit targets.
final class ArtworkView: UIImageView {
    init(_ name: String) {
        super.init(image: UIImage(named: name))
        contentMode = .scaleAspectFill
        clipsToBounds = true
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) { fatalError("Use init(name)") }
}

class PaperCard: UIView {
    let content = UIStackView()

    init(inset: CGFloat = 18) {
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 0.995, green: 0.982, blue: 0.950, alpha: 1)
        layer.cornerRadius = 20
        layer.borderColor = UIColor(red: 0.83, green: 0.78, blue: 0.68, alpha: 0.5).cgColor
        layer.borderWidth = 0.7
        layer.shadowColor = Theme.ink.cgColor
        layer.shadowOpacity = 0.07
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        content.axis = .vertical
        content.spacing = 12
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
        ])
    }

    required init?(coder: NSCoder) { fatalError("Use init(inset)") }
}

func styledLabel(_ text: String, _ style: UIFont.TextStyle, _ color: UIColor = Theme.ink) -> UILabel
{
    let l = UILabel()
    l.text = text
    l.font = .preferredFont(forTextStyle: style)
    l.adjustsFontForContentSizeCategory = true
    l.textColor = color
    l.numberOfLines = 0
    return l
}

final class GameCoverCard: PaperCard {
    init(_ definition: Definition, compact: Bool = false, action: (() -> Void)? = nil) {
        super.init(inset: 0)
        content.spacing = 0
        let art = ArtworkView(definition.template.artwork)
        art.layer.cornerRadius = 20
        let artHeight = art.heightAnchor.constraint(equalToConstant: compact ? 145 : 205)
        artHeight.priority = UILayoutPriority(999)
        artHeight.isActive = true
        content.addArrangedSubview(art)
        let heading = UIStackView()
        heading.axis = .vertical
        heading.spacing = 4
        heading.addArrangedSubview(styledLabel(definition.name, compact ? .headline : .title2))
        heading.addArrangedSubview(styledLabel(compact ? (definition.template == .lucky ? "运气，也是一种策略" : "适可而止，才是高手") : definition.template.subtitle, .caption1))
        heading.translatesAutoresizingMaskIntoConstraints = false
        art.addSubview(heading)
        let shade = UIView()
        shade.backgroundColor = .clear
        shade.translatesAutoresizingMaskIntoConstraints = false
        art.insertSubview(shade, belowSubview: heading)
        NSLayoutConstraint.activate([
            art.heightAnchor.constraint(greaterThanOrEqualTo: heading.heightAnchor, constant: 32),
            heading.topAnchor.constraint(equalTo: art.topAnchor, constant: 16),
            heading.leadingAnchor.constraint(equalTo: art.leadingAnchor, constant: 16),
            heading.trailingAnchor.constraint(equalTo: art.trailingAnchor, constant: -12),
            shade.topAnchor.constraint(equalTo: art.topAnchor),
            shade.leadingAnchor.constraint(equalTo: art.leadingAnchor),
            shade.trailingAnchor.constraint(equalTo: art.trailingAnchor),
            shade.bottomAnchor.constraint(equalTo: heading.bottomAnchor, constant: 10),
        ])
        let footer = UIStackView()
        footer.axis = .vertical
        footer.spacing = 10
        footer.isLayoutMarginsRelativeArrangement = true
        footer.layoutMargins = UIEdgeInsets(top: 7, left: 12, bottom: 10, right: 12)
        footer.addArrangedSubview(GameMetadataView(compact: compact))
        if let action, !compact {
            let b = UIButton(type: .system)
            var c = UIButton.Configuration.filled()
            c.title = compact ? "打开玩法  ›" : "开始游戏  →"
            c.baseBackgroundColor = compact ? .clear : Theme.ink
            c.baseForegroundColor = compact ? Theme.ink : .white
            c.cornerStyle = .capsule
            c.contentInsets = .init(top: 12, leading: 8, bottom: 12, trailing: 8)
            b.configuration = c
            b.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            b.addAction(UIAction { _ in action() }, for: .touchUpInside)
            footer.addArrangedSubview(b)
        }
        content.addArrangedSubview(footer)
        if compact, let action {
            let tap = UIButton(type: .custom)
            tap.accessibilityLabel = definition.name
            tap.translatesAutoresizingMaskIntoConstraints = false
            tap.addAction(UIAction { _ in action() }, for: .touchUpInside)
            addSubview(tap)
            NSLayoutConstraint.activate([tap.leadingAnchor.constraint(equalTo: leadingAnchor), tap.trailingAnchor.constraint(equalTo: trailingAnchor), tap.topAnchor.constraint(equalTo: topAnchor), tap.bottomAnchor.constraint(equalTo: bottomAnchor)])
        }
    }

    required init?(coder: NSCoder) { fatalError("Use init(definition)") }
}

extension Page {
    func section(_ title: String, subtitle: String? = nil) {
        label(title, style: .title2)
        if let subtitle { label(subtitle, style: .caption1, color: .secondaryLabel) }
    }

    func paperGroup(_ views: [UIView], tint: UIColor? = nil) {
        let card = PaperCard()
        if let tint { card.backgroundColor = tint }
        for v in views {
            v.removeFromSuperview()
            card.content.addArrangedSubview(v)
        }
        stack.addArrangedSubview(card)
    }

    func note(_ text: String, symbol: String = "leaf") {
        let card = PaperCard()
        card.backgroundColor = Theme.sage.withAlphaComponent(0.12)
        let l = styledLabel(text, .subheadline)
        let row = UIStackView()
        row.spacing = 12
        row.alignment = .center
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = Theme.sage
        icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        icon.contentMode = .scaleAspectFit
        row.addArrangedSubview(icon)
        row.addArrangedSubview(l)
        card.content.addArrangedSubview(row)
        stack.addArrangedSubview(card)
    }

    func playerBadges(_ session: Session) {
        let row = UIStackView()
        row.axis =
            session.players.count > 2
                || traitCollection.preferredContentSizeCategory.isAccessibilityCategory
            ? .vertical : .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        for (i, p) in session.players.enumerated() {
            let card = PaperCard(inset: 8)
            let active = i == session.current
            card.layer.cornerRadius = 12
            card.backgroundColor = active ? Theme.coral.withAlphaComponent(0.13) : Theme.paper
            card.layer.borderColor = (active ? Theme.coral : Theme.sage.withAlphaComponent(0.25)).cgColor
            let avatar = UIImageView(image: UIImage(systemName: "\(i + 1).circle.fill"))
            avatar.contentMode = .scaleAspectFit
            avatar.tintColor = active ? Theme.coral : Theme.sage
            avatar.isAccessibilityElement = false
            avatar.widthAnchor.constraint(equalToConstant: 30).isActive = true
            let name = styledLabel(p.name, .subheadline, Theme.ink)
            let scoreColor = UIColor(red: 0.65, green: 0.23, blue: 0.13, alpha: 1)
            let score = styledLabel("\(p.score) 分", .subheadline, scoreColor)
            score.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(
                for: .systemFont(ofSize: 15, weight: .bold))
            score.numberOfLines = 1
            score.setContentHuggingPriority(.required, for: .horizontal)
            score.setContentCompressionResistancePriority(.required, for: .horizontal)
            let chip = UIStackView(arrangedSubviews: [avatar, name, score])
            chip.spacing = 6
            chip.alignment = .center
            card.content.addArrangedSubview(chip)
            row.addArrangedSubview(card)
        }
        stack.addArrangedSubview(row)
    }
}

final class RuleDisclosure: PaperCard {
    private let header = UIButton(type: .system)

    func setSummary(_ text: String) { header.configuration?.subtitle = text }

    init(title: String, symbol: String, summary: String, fields: [UIView]) {
        super.init(inset: 0)
        content.spacing = 0
        let header = self.header
        var config = UIButton.Configuration.plain()
        config.title = title
        config.subtitle = summary
        config.image = UIImage(systemName: symbol)
        config.imagePadding = 16
        config.titleAlignment = .leading
        config.baseForegroundColor = Theme.ink
        config.contentInsets = .init(top: 14, leading: 16, bottom: 14, trailing: 28)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { original in
            var result = original
            result.font = .preferredFont(forTextStyle: .headline)
            return result
        }
        header.configuration = config
        header.contentHorizontalAlignment = .leading
        header.accessibilityLabel = title
        header.accessibilityValue = "已收起"
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = Theme.sage
        chevron.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(chevron)
        NSLayoutConstraint.activate([chevron.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -14), chevron.centerYAnchor.constraint(equalTo: header.centerYAnchor), chevron.widthAnchor.constraint(equalToConstant: 7)])
        content.addArrangedSubview(header)
        let details = UIStackView(arrangedSubviews: fields)
        details.axis = .vertical
        details.spacing = 8
        details.isLayoutMarginsRelativeArrangement = true
        details.layoutMargins = UIEdgeInsets(top: 0, left: 14, bottom: 14, right: 14)
        details.isHidden = true
        content.addArrangedSubview(details)
        header.addAction(UIAction { _ in
            details.isHidden.toggle()
            chevron.transform = details.isHidden ? .identity : CGAffineTransform(rotationAngle: .pi / 2)
            header.accessibilityValue = details.isHidden ? "已收起" : "已展开"
        }, for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError() }
}

final class GameBoxCover: UIView {
    init(_ definition: Definition) {
        super.init(frame: .zero)
        let station = definition.template == .station
        let art = ArtworkView(station ? "GameBoxArt" : definition.template.artwork)
        art.contentMode = .scaleAspectFit
        art.translatesAutoresizingMaskIntoConstraints = false
        addSubview(art)
        let name = styledLabel(definition.name, .title2)
        name.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: .systemFont(ofSize: 22, weight: .bold))
        name.textAlignment = .center
        name.numberOfLines = 2
        name.adjustsFontSizeToFitWidth = true
        name.minimumScaleFactor = 0.65
        name.translatesAutoresizingMaskIntoConstraints = false
        addSubview(name)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalTo: widthAnchor, multiplier: 0.86),
            art.leadingAnchor.constraint(equalTo: leadingAnchor), art.trailingAnchor.constraint(equalTo: trailingAnchor),
            art.topAnchor.constraint(equalTo: topAnchor), art.bottomAnchor.constraint(equalTo: bottomAnchor),
            name.topAnchor.constraint(equalTo: topAnchor, constant: 30),
            name.leadingAnchor.constraint(equalTo: leadingAnchor, constant: station ? 65 : 35), name.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

/// Quiet printed dice ornament, separate from playable dice and accessibility.
final class DicePageOrnament: UIView {
    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        heightAnchor.constraint(equalToConstant: 64).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("Use init()") }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let center = bounds.midX
        Theme.sage.withAlphaComponent(0.22).setStroke()
        let rules = UIBezierPath()
        rules.move(to: CGPoint(x: max(12, center - 116), y: 34))
        rules.addLine(to: CGPoint(x: center - 54, y: 34))
        rules.move(to: CGPoint(x: center + 54, y: 34))
        rules.addLine(to: CGPoint(x: min(bounds.width - 12, center + 116), y: 34))
        rules.lineWidth = 0.8
        rules.stroke()

        func die(x: CGFloat, y: CGFloat, angle: CGFloat, color: UIColor, pips: [CGPoint]) {
            context.saveGState()
            context.translateBy(x: x, y: y)
            context.rotate(by: angle)
            let side = UIBezierPath()
            side.move(to: CGPoint(x: 13, y: -13))
            side.addLine(to: CGPoint(x: 19, y: -18))
            side.addLine(to: CGPoint(x: 19, y: 8))
            side.addLine(to: CGPoint(x: 13, y: 14))
            side.close()
            color.withAlphaComponent(0.13).setFill()
            side.fill()
            color.withAlphaComponent(0.5).setStroke()
            side.lineWidth = 1
            side.stroke()
            let top = UIBezierPath()
            top.move(to: CGPoint(x: -13, y: -13))
            top.addLine(to: CGPoint(x: -7, y: -18))
            top.addLine(to: CGPoint(x: 19, y: -18))
            top.addLine(to: CGPoint(x: 13, y: -13))
            top.close()
            top.lineWidth = 1
            top.stroke()
            let face = UIBezierPath(roundedRect: CGRect(x: -14, y: -14, width: 28, height: 28), cornerRadius: 5)
            Theme.paper.setFill()
            face.fill()
            color.withAlphaComponent(0.65).setStroke()
            face.lineWidth = 1.2
            face.stroke()
            color.withAlphaComponent(0.7).setFill()
            for pip in pips {
                UIBezierPath(ovalIn: CGRect(x: pip.x - 2, y: pip.y - 2, width: 4, height: 4)).fill()
            }
            context.restoreGState()
        }
        die(x: center - 23, y: 34, angle: -0.20, color: Theme.sage,
            pips: [CGPoint(x: -6, y: -6), .zero, CGPoint(x: 6, y: 6)])
        die(x: center + 19, y: 36, angle: 0.18, color: Theme.coral,
            pips: [CGPoint(x: -6, y: -6), CGPoint(x: 6, y: -6), .zero,
                   CGPoint(x: -6, y: 6), CGPoint(x: 6, y: 6)])
    }
}


/// Consistent native symbols instead of decorative Unicode substitutes.
final class GameMetadataView: UIStackView {
    init(compact: Bool = false) {
        super.init(frame: .zero)
        axis = .horizontal
        alignment = .center
        distribution = .equalSpacing
        spacing = 6
        let items = compact
            ? [("person.2", "1–4人"), ("leaf", "离线")]
            : [("person.2", "1–4人"), ("clock", "约5分钟"), ("leaf", "离线可玩")]
        for (symbol, text) in items {
            let label = styledLabel(text, .caption1)
            let icon = UIImageView(image: UIImage(systemName: symbol))
            icon.tintColor = Theme.ink
            icon.contentMode = .scaleAspectFit
            icon.isAccessibilityElement = false
            icon.widthAnchor.constraint(equalToConstant: 14).isActive = true
            let item = UIStackView(arrangedSubviews: [icon, label])
            item.spacing = 4
            item.alignment = .center
            addArrangedSubview(item)
        }
    }
    required init(coder: NSCoder) { fatalError("Use init(compact:)") }
}

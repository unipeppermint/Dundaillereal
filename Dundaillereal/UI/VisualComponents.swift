import UIKit

extension Template {
    var artwork: String { switch self { case .station: return "StationArt"; case .lucky: return "LuckyArt"; case .risk: return "RiskArt" } }
}

/// Decoration never contains live points, scores or hit targets.
final class ArtworkView: UIImageView {
    init(_ name: String) {
        super.init(image: UIImage(named: name)); contentMode = .scaleAspectFill; clipsToBounds = true
        isAccessibilityElement = false
    }
    required init?(coder: NSCoder) { fatalError("Use init(name)") }
}

class PaperCard: UIView {
    let content = UIStackView()
    init(inset: CGFloat = 18) {
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 0.995, green: 0.982, blue: 0.950, alpha: 1)
        layer.cornerRadius = 20; layer.borderColor = UIColor(red: 0.83, green: 0.78, blue: 0.68, alpha: 0.5).cgColor; layer.borderWidth = 0.7
        layer.shadowColor = Theme.ink.cgColor; layer.shadowOpacity = 0.07; layer.shadowOffset = CGSize(width: 0, height: 4); layer.shadowRadius = 8
        content.axis = .vertical; content.spacing = 12; content.translatesAutoresizingMaskIntoConstraints = false; addSubview(content)
        NSLayoutConstraint.activate([content.topAnchor.constraint(equalTo: topAnchor, constant: inset), content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset), content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset), content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset)])
    }
    required init?(coder: NSCoder) { fatalError("Use init(inset)") }
}

func styledLabel(_ text: String, _ style: UIFont.TextStyle, _ color: UIColor = Theme.ink) -> UILabel {
    let l = UILabel(); l.text = text; l.font = .preferredFont(forTextStyle: style); l.adjustsFontForContentSizeCategory = true; l.textColor = color; l.numberOfLines = 0; return l
}

final class GameCoverCard: PaperCard {
    init(_ definition: Definition, compact: Bool = false, action: (() -> Void)? = nil) {
        super.init(inset: 0)
        content.spacing = 0
        let art = ArtworkView(definition.template.artwork); art.layer.cornerRadius = 20
        let artHeight = art.heightAnchor.constraint(equalToConstant: compact ? 145 : 228); artHeight.priority = UILayoutPriority(999); artHeight.isActive = true
        content.addArrangedSubview(art)
        let heading = UIStackView(); heading.axis = .vertical; heading.spacing = 5
        heading.addArrangedSubview(styledLabel(definition.name, compact ? .headline : .title1))
        if !compact { heading.addArrangedSubview(styledLabel(definition.template.subtitle, .subheadline)) }
        heading.translatesAutoresizingMaskIntoConstraints = false; art.addSubview(heading)
        let shade = UIView(); shade.backgroundColor = Theme.paper.withAlphaComponent(0.9); shade.translatesAutoresizingMaskIntoConstraints = false; art.insertSubview(shade, belowSubview: heading)
        NSLayoutConstraint.activate([art.heightAnchor.constraint(greaterThanOrEqualTo: heading.heightAnchor, constant: 32), heading.topAnchor.constraint(equalTo: art.topAnchor, constant: 16), heading.leadingAnchor.constraint(equalTo: art.leadingAnchor, constant: 16), heading.trailingAnchor.constraint(equalTo: art.trailingAnchor, constant: -12), shade.topAnchor.constraint(equalTo: art.topAnchor), shade.leadingAnchor.constraint(equalTo: art.leadingAnchor), shade.trailingAnchor.constraint(equalTo: art.trailingAnchor), shade.bottomAnchor.constraint(equalTo: heading.bottomAnchor, constant: 10)])
        let footer = UIStackView(); footer.axis = .vertical; footer.spacing = 10; footer.isLayoutMarginsRelativeArrangement = true; footer.layoutMargins = UIEdgeInsets(top: 12, left: 14, bottom: 14, right: 14)
        footer.addArrangedSubview(styledLabel(compact ? "1–4 人 · 离线" : "♧  1–4 人     ◷  约 5 分钟     离线可玩", .caption1))
        if let action {
            let b = UIButton(type: .system); var c = UIButton.Configuration.filled(); c.title = compact ? "打开玩法  ›" : "开始游戏  →"; c.baseBackgroundColor = compact ? .clear : Theme.ink; c.baseForegroundColor = compact ? Theme.ink : .white; c.cornerStyle = .capsule; c.contentInsets = .init(top: 12, leading: 8, bottom: 12, trailing: 8); b.configuration = c; b.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true; b.addAction(UIAction { _ in action() }, for: .touchUpInside); footer.addArrangedSubview(b)
        }
        content.addArrangedSubview(footer)
    }
    required init?(coder: NSCoder) { fatalError("Use init(definition)") }
}

extension Page {
    func section(_ title: String, subtitle: String? = nil) {
        label(title, style: .title2)
        if let subtitle { label(subtitle, style: .caption1, color: .secondaryLabel) }
    }
    func paperGroup(_ views: [UIView], tint: UIColor? = nil) {
        let card = PaperCard(); if let tint { card.backgroundColor = tint }
        for v in views { v.removeFromSuperview(); card.content.addArrangedSubview(v) }; stack.addArrangedSubview(card)
    }
    func note(_ text: String, symbol: String = "leaf") {
        let card = PaperCard(); card.backgroundColor = Theme.sage.withAlphaComponent(0.12)
        let l = styledLabel(text, .subheadline); let row = UIStackView(); row.spacing = 12; row.alignment = .center
        let icon = UIImageView(image: UIImage(systemName: symbol)); icon.tintColor = Theme.sage; icon.widthAnchor.constraint(equalToConstant: 24).isActive = true; icon.contentMode = .scaleAspectFit; row.addArrangedSubview(icon); row.addArrangedSubview(l); card.content.addArrangedSubview(row); stack.addArrangedSubview(card)
    }
    func playerBadges(_ session: Session) {
        let row = UIStackView(); row.axis = session.players.count > 2 || traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal; row.spacing = 8; row.distribution = .fillEqually
        for (i,p) in session.players.enumerated() {
            let card = PaperCard(inset: 12); let active = i == session.current
            card.backgroundColor = active ? Theme.coral.withAlphaComponent(0.13) : Theme.paper
            card.layer.borderColor = (active ? Theme.coral : Theme.sage.withAlphaComponent(0.25)).cgColor
            card.content.addArrangedSubview(styledLabel("\(active ? "▶" : "○") \(p.name)   \(p.score) 分", .subheadline)); row.addArrangedSubview(card)
        }; stack.addArrangedSubview(row)
    }
}

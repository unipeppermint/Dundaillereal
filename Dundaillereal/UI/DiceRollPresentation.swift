import UIKit
import AVFoundation

/// Presentation only: the caller has already committed the final dice to disk.
/// This view never generates values or submits game actions.
final class DiceRollPresentation: UIView {
    private let dice: [RollingDieView]
    private let moving: Set<Int>
    private var completion: (() -> Void)?
    private var work: [DispatchWorkItem] = []
    private var cancelled = false
    private var ticker: CADisplayLink?
    private var started: CFTimeInterval = 0
    private var audio: AVAudioPlayer?
    private let impact = UIImpactFeedbackGenerator(style: .light)

    init(values: [Int], moving: Set<Int>, completion: @escaping () -> Void) {
        self.moving = moving
        self.completion = completion
        dice = values.map { RollingDieView(value: $0) }
        super.init(frame: .zero)
        if let url = Bundle.main.url(forResource: "dice-roll", withExtension: "wav") {
            audio = try? AVAudioPlayer(contentsOf: url)
            audio?.prepareToPlay()
        }
        backgroundColor = Theme.paper
        accessibilityIdentifier = "dice-roll-presentation"
        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 60
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        let title = styledLabel("投掷中…", .title1)
        title.textAlignment = .center
        content.addArrangedSubview(title)
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = values.count > 3 ? 10 : 18
        row.distribution = .fillEqually
        for (index, die) in dice.enumerated() {
            die.isUserInteractionEnabled = false
            die.accessibilityLabel = moving.contains(index) ? "骰子正在落桌" : "保留的骰子，\(values[index]) 点"
            row.addArrangedSubview(die)
        }
        content.addArrangedSubview(row)
        let caption = styledLabel(moving.count == values.count ? "让好运，轻轻落在桌上" : "保留的骰子不动，重掷其余骰子", .subheadline, .secondaryLabel)
        caption.textAlignment = .center
        content.addArrangedSubview(caption)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 28),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -28),
            content.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError("Use init(values:moving:completion:)") }

    func start() {
        layoutIfNeeded()
        UIAccessibility.post(notification: .announcement, argument: "投掷中")
        if UIAccessibility.isReduceMotionEnabled {
            playSound(reduced: true)
            alpha = 0
            UIView.animate(withDuration: 0.12, animations: { self.alpha = 1 }) { [weak self] _ in
                self?.landingFeedback()
                self?.finish()
            }
            return
        }
        alpha = 0
        UIView.animate(withDuration: 0.08) { self.alpha = 1 }
        if UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true { impact.prepare() }
        playSound(reduced: false)
        started = CACurrentMediaTime()
        for (index, die) in dice.enumerated() where moving.contains(index) { die.pose(progress: 0, index: index) }
        ticker = CADisplayLink(target: self, selector: #selector(frame(_:)))
        ticker?.add(to: .main, forMode: .common)
        schedule(after: 1.04) { [weak self] in self?.landingFeedback() }
        schedule(after: 1.40 + Double(moving.max() ?? 0) * 0.035) { [weak self] in self?.finish() }
    }

    @objc private func frame(_ link: CADisplayLink) {
        let elapsed = link.timestamp - started
        for (index, die) in dice.enumerated() where moving.contains(index) {
            die.pose(progress: (elapsed - Double(index) * 0.035) / 1.2, index: index)
        }
    }

    private func playSound(reduced: Bool) {
        guard UserDefaults.standard.object(forKey: "sound") as? Bool ?? true else { return }
        do {
            // Respect the silent switch and mix with the user's music.
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            // The recorded roll starts with its clearest impact. Reduced motion
            // uses that short attack rather than seeking into the quiet tail.
            audio?.currentTime = reduced ? 0.06 : 0
            audio?.volume = 0.8
            audio?.play()
        } catch {
            // Audio availability must not block an already saved game action.
            print("Dice audio unavailable: \(error.localizedDescription)")
        }
    }

    private func landingFeedback() {
        guard !cancelled, window != nil else { return }
        if UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true { impact.impactOccurred(intensity: 0.7) }

    }

    private func schedule(after delay: Double, _ block: @escaping () -> Void) {
        let item = DispatchWorkItem { [weak self] in guard self?.cancelled == false else { return }; block() }
        work.append(item)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }
    private func finish() {
        guard !cancelled else { return }
        ticker?.invalidate()
        ticker = nil
        let callback = completion
        completion = nil
        callback?()
    }
    func cancel() {
        cancelled = true
        ticker?.invalidate()
        ticker = nil
        audio?.stop()
        completion = nil
        work.forEach { $0.cancel() }
        work.removeAll()
        dice.forEach { $0.layer.removeAllAnimations(); $0.layer.transform = CATransform3DIdentity }
        layer.removeAllAnimations()
        removeFromSuperview()
    }
}

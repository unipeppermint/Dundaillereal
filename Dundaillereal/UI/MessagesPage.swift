import UIKit

private struct InboxMessage {
    let id: String
    let category: String
    let title: String
    let body: String

    static let localMessages = [
        InboxMessage(
            id: "welcome", category: "GETTING STARTED", title: "Welcome to Rollweave",
            body: "Good games start with your rules. Explore our dice games, create your own in the Rule Workshop, and take turns with friends on one iPhone.\n\nYour games and scores stay on your device. Pick a game and enjoy your first roll!")
    ]
}

/// An on-device inbox; viewing messages does not request permissions or contact a service.
final class MessagesPage: UITableViewController {
    private let messages = InboxMessage.localMessages

    init() { super.init(style: .insetGrouped) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Messages"
        tableView.backgroundColor = Theme.paper
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 240
        tableView.allowsSelection = false
        tableView.accessibilityIdentifier = "messages.list"
        tableView.register(MessageCell.self, forCellReuseIdentifier: "message")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { messages.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "message", for: indexPath) as! MessageCell
        cell.configure(messages[indexPath.section])
        return cell
    }
}

private final class MessageCell: UITableViewCell {
    private let categoryLabel = UILabel()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor(red: 0.995, green: 0.982, blue: 0.950, alpha: 1)
        let icon = UIImageView(image: UIImage(systemName: "envelope.open.fill"))
        icon.tintColor = Theme.coral
        icon.contentMode = .scaleAspectFit
        icon.isAccessibilityElement = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24)
        ])
        let heading = UIStackView(arrangedSubviews: [icon, categoryLabel])
        heading.spacing = 10
        heading.alignment = .center
        categoryLabel.font = .preferredFont(forTextStyle: .caption1)
        categoryLabel.textColor = Theme.sage
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = Theme.ink
        titleLabel.accessibilityTraits.insert(.header)
        bodyLabel.font = .preferredFont(forTextStyle: .body)
        bodyLabel.textColor = Theme.ink
        for label in [categoryLabel, titleLabel, bodyLabel] {
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
        }
        let stack = UIStackView(arrangedSubviews: [heading, titleLabel, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -22)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ message: InboxMessage) {
        accessibilityIdentifier = "messages.\(message.id)"
        categoryLabel.text = message.category
        titleLabel.text = message.title
        bodyLabel.text = message.body
    }
}

import UIKit
import DIDWalletSDK

final class JinBonCertificateViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let stateView = UIView()
    private var credentials: [VerifiableCredential] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "인증서"
        view.backgroundColor = ColorPalette.canvas
        configureNavigationBar()
        configureTable()
        configureStateView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCredentials()
    }

    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ColorPalette.canvas
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: ColorPalette.ink]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func configureTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = ColorPalette.canvas
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 28, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(JinBonCertificateCell.self, forCellReuseIdentifier: "certificate")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureStateView() {
        stateView.backgroundColor = .clear
        let iconBox = UIView()
        iconBox.backgroundColor = ColorPalette.softBlue
        iconBox.layer.cornerRadius = 30
        iconBox.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView(image: UIImage(systemName: "checkmark.seal"))
        icon.tintColor = ColorPalette.primary
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBox.addSubview(icon)

        let title = UILabel()
        title.text = "아직 발급된 인증서가 없습니다"
        title.font = .systemFont(ofSize: 18, weight: .bold)
        title.textColor = ColorPalette.ink
        title.textAlignment = .center

        let detail = UILabel()
        detail.text = "원본 영상을 등록하면 진본 인증서가\n이 지갑에 안전하게 저장됩니다."
        detail.numberOfLines = 0
        detail.font = .systemFont(ofSize: 14)
        detail.textColor = ColorPalette.secondaryText
        detail.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [iconBox, title, detail])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stateView.addSubview(stack)
        NSLayoutConstraint.activate([
            iconBox.widthAnchor.constraint(equalToConstant: 60), iconBox.heightAnchor.constraint(equalToConstant: 60),
            icon.centerXAnchor.constraint(equalTo: iconBox.centerXAnchor), icon.centerYAnchor.constraint(equalTo: iconBox.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 28), icon.heightAnchor.constraint(equalToConstant: 28),
            stack.centerXAnchor.constraint(equalTo: stateView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: stateView.centerYAnchor, constant: -40),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: stateView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: stateView.trailingAnchor, constant: -24)
        ])
        tableView.backgroundView = stateView
    }

    private func loadCredentials() {
        guard Properties.isLoggedIn(), let userId = Properties.getUserId() else {
            credentials = []
            tableView.reloadData()
            tableView.backgroundView?.isHidden = false
            return
        }
        Task {
            do {
                let token = try await SDKUtils.createWalletToken(purpose: .LIST_VC, userId: userId)
                let items = try WalletAPI.shared.getAllCredentials(hWalletToken: token) ?? []
                await MainActor.run {
                    self.credentials = items
                    self.tableView.backgroundView?.isHidden = !items.isEmpty
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.credentials = []
                    self.tableView.backgroundView?.isHidden = false
                    self.tableView.reloadData()
                }
            }
        }
    }
}

extension JinBonCertificateViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { credentials.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "certificate", for: indexPath) as! JinBonCertificateCell
        cell.configure(credentials[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 176 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = credentials[indexPath.row]
        let detail = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "VCDetailViewController") as! VCDetailViewController
        detail.setVcInfo(vc: vc, zkpVC: nil, zkpSchema: nil)
        detail.modalPresentationStyle = .fullScreen
        present(detail, animated: true)
    }
}

private final class JinBonCertificateCell: UITableViewCell {
    private let card = UIView()
    private let titleLabel = UILabel()
    private let idLabel = UILabel()
    private let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildUI() {
        backgroundColor = .clear
        selectionStyle = .none
        card.backgroundColor = ColorPalette.ink
        card.layer.cornerRadius = 22
        card.layer.cornerCurve = .continuous
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        let mark = UILabel()
        mark.text = "J"
        mark.textAlignment = .center
        mark.font = .systemFont(ofSize: 18, weight: .black)
        mark.textColor = .white
        mark.backgroundColor = ColorPalette.primary
        mark.layer.cornerRadius = 10
        mark.clipsToBounds = true
        mark.translatesAutoresizingMaskIntoConstraints = false

        let badge = UILabel()
        badge.text = "VERIFIABLE CREDENTIAL"
        badge.font = .systemFont(ofSize: 11, weight: .bold)
        badge.textColor = UIColor.white.withAlphaComponent(0.82)
        badge.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        idLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        idLabel.textColor = UIColor.white.withAlphaComponent(0.76)
        idLabel.lineBreakMode = .byTruncatingMiddle
        idLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .systemFont(ofSize: 13, weight: .medium)
        dateLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        [mark, badge, titleLabel, idLabel, dateLabel].forEach(card.addSubview)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            mark.topAnchor.constraint(equalTo: card.topAnchor, constant: 18), mark.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            mark.widthAnchor.constraint(equalToConstant: 38), mark.heightAnchor.constraint(equalToConstant: 38),
            badge.leadingAnchor.constraint(equalTo: mark.trailingAnchor, constant: 12), badge.centerYAnchor.constraint(equalTo: mark.centerYAnchor),
            titleLabel.topAnchor.constraint(equalTo: mark.bottomAnchor, constant: 17), titleLabel.leadingAnchor.constraint(equalTo: mark.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            idLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 7), idLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            idLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor), dateLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    func configure(_ credential: VerifiableCredential) {
        titleLabel.text = "진본 디지털 인증서"
        idLabel.text = credential.id
        dateLabel.text = "발급일  \(SDKUtils.convertDateFormat(dateString: credential.issuanceDate) ?? credential.issuanceDate)"
    }
}

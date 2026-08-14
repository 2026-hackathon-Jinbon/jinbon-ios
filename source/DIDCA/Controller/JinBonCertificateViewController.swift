import UIKit
import DIDWalletSDK

final class JinBonCertificateViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let stateView = UIView()
    private let stateIcon = UIImageView()
    private let stateTitle = UILabel()
    private let stateDetail = UILabel()
    private let retryButton = UIButton(type: .system)
    private var credentials: [VerifiableCredential] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "등록 보증서"
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
        tableView.register(JinBonCertificateCell.self, forCellReuseIdentifier: CellID.certificate.rawValue)
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = ColorPalette.primary
        refreshControl.addTarget(self, action: #selector(refreshCredentials), for: .valueChanged)
        tableView.refreshControl = refreshControl
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
        stateIcon.image = UIImage(systemName: "checkmark.seal")
        stateIcon.tintColor = ColorPalette.primary
        stateIcon.translatesAutoresizingMaskIntoConstraints = false
        iconBox.addSubview(stateIcon)

        stateTitle.font = .jinBonFont(ofSize: 18, weight: .bold)
        stateTitle.textColor = ColorPalette.ink
        stateTitle.textAlignment = .center

        stateDetail.numberOfLines = 0
        stateDetail.font = .jinBonFont(ofSize: 14)
        stateDetail.textColor = ColorPalette.secondaryText
        stateDetail.textAlignment = .center

        retryButton.setTitle("다시 시도", for: .normal)
        retryButton.titleLabel?.font = .jinBonFont(ofSize: 14, weight: .bold)
        retryButton.tintColor = ColorPalette.primary
        retryButton.addTarget(self, action: #selector(retryLoad), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [iconBox, stateTitle, stateDetail, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stateView.addSubview(stack)
        NSLayoutConstraint.activate([
            iconBox.widthAnchor.constraint(equalToConstant: 60), iconBox.heightAnchor.constraint(equalToConstant: 60),
            stateIcon.centerXAnchor.constraint(equalTo: iconBox.centerXAnchor), stateIcon.centerYAnchor.constraint(equalTo: iconBox.centerYAnchor),
            stateIcon.widthAnchor.constraint(equalToConstant: 28), stateIcon.heightAnchor.constraint(equalToConstant: 28),
            stack.centerXAnchor.constraint(equalTo: stateView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: stateView.centerYAnchor, constant: -40),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: stateView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: stateView.trailingAnchor, constant: -24)
        ])
        tableView.backgroundView = stateView
        showEmptyState()
    }

    private func loadCredentials() {
        guard Properties.isLoggedIn(), let userId = Properties.getUserId() else {
            credentials = []
            tableView.reloadData()
            tableView.backgroundView?.isHidden = false
            stateIcon.image = UIImage(systemName: "person.crop.circle.badge.exclamationmark")
            stateTitle.text = "로그인이 필요합니다"
            stateDetail.setJinBonText("로그인하면 진본이 발급한 등록 보증서를\n이 Wallet에서 확인할 수 있어요.", lineSpacing: 5)
            retryButton.isHidden = true
            tableView.refreshControl?.endRefreshing()
            return
        }
        Task {
            do {
                let token = try await SDKUtils.createWalletToken(purpose: .LIST_VC, userId: userId)
                let items = (try WalletAPI.shared.getAllCredentials(hWalletToken: token) ?? [])
                    .filter { Self.isJinBonCredential($0) }
                await MainActor.run {
                    self.credentials = items
                    self.tableView.backgroundView?.isHidden = !items.isEmpty
                    if items.isEmpty { self.showEmptyState() }
                    self.tableView.reloadData()
                    self.tableView.refreshControl?.endRefreshing()
                }
            } catch {
                await MainActor.run {
                    self.credentials = []
                    self.tableView.backgroundView?.isHidden = false
                    self.stateIcon.image = UIImage(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                    self.stateTitle.text = "보증서를 불러오지 못했습니다"
                    self.stateDetail.setJinBonText(
                        "Wallet 상태를 확인한 뒤\n다시 시도해주세요.", lineSpacing: 5)
                    self.retryButton.isHidden = false
                    self.tableView.reloadData()
                    self.tableView.refreshControl?.endRefreshing()
                }
            }
        }
    }

    private func showEmptyState() {
        stateIcon.image = UIImage(systemName: "checkmark.seal")
        stateTitle.text = "아직 발급된 등록 보증서가 없습니다"
        stateDetail.setJinBonText("영상의 디지털 지문을 등록하면\n온체인 등록 보증서를 Wallet에 받을 수 있어요.", lineSpacing: 5)
        retryButton.isHidden = true
    }

    @objc private func refreshCredentials() {
        loadCredentials()
    }

    @objc private func retryLoad() {
        loadCredentials()
    }

    private static func isJinBonCredential(_ credential: VerifiableCredential) -> Bool {
        let schema = credential.credentialSchema.id
        if schema == URLs.JINBON_VC_SCHEMA_ID || schema.hasSuffix("/\(URLs.JINBON_VC_SCHEMA_ID)") {
            return true
        }
        guard let components = URLComponents(string: schema) else {
            return schema.contains(URLs.JINBON_VC_SCHEMA_ID)
        }
        return components.queryItems?.contains {
            ($0.name == "name" || $0.name == "id") && $0.value == URLs.JINBON_VC_SCHEMA_ID
        } == true
    }
}

extension JinBonCertificateViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { credentials.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID.certificate.rawValue, for: indexPath) as! JinBonCertificateCell
        cell.configure(credentials[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 176 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = credentials[indexPath.row]
        navigationController?.pushViewController(
            JinBonCertificateDetailViewController(credential: vc), animated: true)
    }
}

private final class JinBonCertificateDetailViewController: UIViewController {
    private let credential: VerifiableCredential
    private let statusLabel = UILabel()

    init(credential: VerifiableCredential) {
        self.credential = credential
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "등록 보증서 상세"
        view.backgroundColor = ColorPalette.canvas
        buildUI()
        loadStatus()
    }

    private func buildUI() {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -36)
        ])

        stack.addArrangedSubview(makeHero())

        let sectionTitle = UILabel()
        sectionTitle.text = "진본이 보증하는 내용"
        sectionTitle.font = .jinBonFont(ofSize: 18, weight: .bold)
        sectionTitle.textColor = ColorPalette.ink
        stack.addArrangedSubview(sectionTitle)

        let claimsCard = UIStackView()
        claimsCard.axis = .vertical
        claimsCard.spacing = 0
        claimsCard.backgroundColor = .white
        claimsCard.layer.cornerRadius = 20
        claimsCard.layer.cornerCurve = .continuous
        claimsCard.isLayoutMarginsRelativeArrangement = true
        claimsCard.layoutMargins = UIEdgeInsets(top: 6, left: 18, bottom: 6, right: 18)

        for (index, claim) in credential.credentialSubject.claims.enumerated() {
            claimsCard.addArrangedSubview(makeClaimRow(caption: localizedCaption(claim.caption), value: claim.value))
            if index < credential.credentialSubject.claims.count - 1 {
                let divider = UIView()
                divider.backgroundColor = ColorPalette.canvas
                divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                claimsCard.addArrangedSubview(divider)
            }
        }
        stack.addArrangedSubview(claimsCard)

        let metadata = UILabel()
        metadata.numberOfLines = 0
        metadata.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        metadata.textColor = ColorPalette.secondaryText
        metadata.setJinBonText("""
        발급기관
        \(credential.issuer.name ?? "진본") · \(credential.issuer.id)

        VC ID
        \(credential.id)

        발급일
        \(SDKUtils.convertDateFormat(dateString: credential.issuanceDate) ?? credential.issuanceDate)
        """, lineSpacing: 5)
        let metadataCard = UIView()
        metadataCard.backgroundColor = ColorPalette.softBlue
        metadataCard.layer.cornerRadius = 18
        metadata.translatesAutoresizingMaskIntoConstraints = false
        metadataCard.addSubview(metadata)
        NSLayoutConstraint.activate([
            metadata.topAnchor.constraint(equalTo: metadataCard.topAnchor, constant: 18),
            metadata.leadingAnchor.constraint(equalTo: metadataCard.leadingAnchor, constant: 18),
            metadata.trailingAnchor.constraint(equalTo: metadataCard.trailingAnchor, constant: -18),
            metadata.bottomAnchor.constraint(equalTo: metadataCard.bottomAnchor, constant: -18)
        ])
        stack.addArrangedSubview(metadataCard)

        let notice = UILabel()
        notice.numberOfLines = 0
        notice.font = .jinBonFont(ofSize: 13, weight: .regular)
        notice.textColor = ColorPalette.secondaryText
        notice.setJinBonText(
            "이 보증서는 영상 디지털 지문의 블록체인 등록 사실과 등록 주체를 진본이 확인했다는 뜻입니다. 영상 내용의 사실성이나 법적 저작권은 보증하지 않습니다.",
            lineSpacing: 5
        )
        stack.addArrangedSubview(notice)
    }

    private func makeHero() -> UIView {
        let card = UIView()
        card.backgroundColor = ColorPalette.ink
        card.layer.cornerRadius = 24
        card.layer.cornerCurve = .continuous

        let icon = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        let title = UILabel()
        title.text = "영상 블록체인 등록 보증서"
        title.font = .jinBonFont(ofSize: 22, weight: .bold)
        title.textColor = .white
        let description = UILabel()
        description.text = "JinBon Verifiable Credential"
        description.font = .jinBonFont(ofSize: 12, weight: .semibold)
        description.textColor = UIColor.white.withAlphaComponent(0.68)
        statusLabel.text = "상태 확인 중"
        statusLabel.font = .jinBonFont(ofSize: 12, weight: .bold)
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        statusLabel.layer.cornerRadius = 13
        statusLabel.clipsToBounds = true
        statusLabel.heightAnchor.constraint(equalToConstant: 28).isActive = true
        let labels = UIStackView(arrangedSubviews: [title, description, statusLabel])
        labels.axis = .vertical
        labels.alignment = .leading
        labels.spacing = 7
        let row = UIStackView(arrangedSubviews: [icon, labels])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 14
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 22),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -22),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
            icon.widthAnchor.constraint(equalToConstant: 38),
            icon.heightAnchor.constraint(equalToConstant: 38)
        ])
        return card
    }

    private func makeClaimRow(caption: String, value: String) -> UIView {
        let captionLabel = UILabel()
        captionLabel.text = caption
        captionLabel.font = .jinBonFont(ofSize: 13, weight: .semibold)
        captionLabel.textColor = ColorPalette.secondaryText
        let valueLabel = UILabel()
        valueLabel.text = value.isEmpty ? "정보 없음" : value
        valueLabel.font = .jinBonFont(ofSize: 14, weight: .medium)
        valueLabel.textColor = ColorPalette.ink
        valueLabel.numberOfLines = 0
        valueLabel.lineBreakMode = .byCharWrapping
        let row = UIStackView(arrangedSubviews: [captionLabel, valueLabel])
        row.axis = .vertical
        row.spacing = 7
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 0)
        return row
    }

    private func localizedCaption(_ caption: String) -> String {
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let claimId = trimmed.split(separator: ".").last.map(String.init) ?? trimmed
        let aliases = [
            "videoHash": "영상 해시", "uploaderDid": "등록자 DID",
            "uploadTimestamp": "등록 시각", "videoTitle": "영상 제목",
            "credentialType": "보증서 종류", "assuranceType": "보증 범위",
            "videoCommitment": "영상 디지털 지문", "registrantDid": "등록자 DID",
            "blockchainNetwork": "블록체인 네트워크", "chainId": "체인 ID",
            "contractAddress": "컨트랙트 주소", "transactionHash": "트랜잭션 해시",
            "blockNumber": "블록 번호", "registeredAt": "온체인 등록 시각",
            "schemaVersion": "보증서 스키마 버전"
        ]
        return aliases[claimId] ?? trimmed
    }

    private func loadStatus() {
        Task { @MainActor in
            do {
                let status = try await VCStatusGetter.getStatus(vcId: credential.id)
                switch status {
                case .ACTIVE:
                    statusLabel.text = "  유효한 보증서  "
                    statusLabel.backgroundColor = ColorPalette.success.withAlphaComponent(0.75)
                case .INACTIVE:
                    statusLabel.text = "  비활성 보증서  "
                    statusLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.8)
                case .REVOKED:
                    statusLabel.text = "  폐기됨  "
                    statusLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.7)
                @unknown default:
                    statusLabel.text = "  알 수 없는 상태  "
                    statusLabel.backgroundColor = UIColor.systemGray.withAlphaComponent(0.75)
                }
            } catch {
                statusLabel.text = "  상태 확인 불가  "
            }
        }
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
        mark.font = .jinBonFont(ofSize: 18, weight: .black)
        mark.textColor = .white
        mark.backgroundColor = ColorPalette.primary
        mark.layer.cornerRadius = 10
        mark.clipsToBounds = true
        mark.translatesAutoresizingMaskIntoConstraints = false

        let badge = UILabel()
        badge.text = "VERIFIABLE CREDENTIAL"
        badge.font = .jinBonFont(ofSize: 11, weight: .bold)
        badge.textColor = UIColor.white.withAlphaComponent(0.82)
        badge.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .jinBonFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        idLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        idLabel.textColor = UIColor.white.withAlphaComponent(0.76)
        idLabel.lineBreakMode = .byTruncatingMiddle
        idLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .jinBonFont(ofSize: 13, weight: .medium)
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
        titleLabel.text = "영상 블록체인 등록 보증서"
        idLabel.text = credential.id
        dateLabel.text = "발급일  \(SDKUtils.convertDateFormat(dateString: credential.issuanceDate) ?? credential.issuanceDate)"
        isAccessibilityElement = true
        accessibilityLabel = "\(titleLabel.text ?? ""), \(dateLabel.text ?? "")"
        accessibilityHint = "등록 보증서 상세 내용을 엽니다"
        accessibilityTraits = .button
    }
}

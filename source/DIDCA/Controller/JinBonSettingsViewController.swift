import UIKit
import DIDWalletSDK

final class JinBonSettingsViewController: UIViewController {

    private let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "설정"
        view.backgroundColor = ColorPalette.canvas
        configureNavigationBar()
        buildUI()
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

    private func buildUI() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor), scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -30)
        ])

        stack.addArrangedSubview(profileCard())
        if Properties.isLoggedIn() {
            stack.addArrangedSubview(sectionTitle("디지털 신원 및 보안"))
            stack.addArrangedSubview(menuCard([
                ("person.text.rectangle", "내 디지털 신원", "DID와 연결 상태 확인", #selector(showDid)),
                ("lock.shield", "Wallet 보안", "PIN 및 생체인증 관리", #selector(showWalletSecurity)),
                ("checkmark.seal", "인증서 관리", "발급·폐기 상태 확인", #selector(showCertificates))
            ]))
            stack.addArrangedSubview(sectionTitle("계정"))
            stack.addArrangedSubview(menuCard([
                ("rectangle.portrait.and.arrow.right", "로그아웃", "모바일 신분증으로 다시 로그인", #selector(logoutTapped))
            ], destructive: true))
        } else {
            stack.addArrangedSubview(sectionTitle("비회원 이용"))
            stack.addArrangedSubview(menuCard([
                ("checkmark.shield", "영상 검증", "로그인 없이 진본 여부 확인", #selector(openGuestVerification)),
                ("arrow.backward", "회원가입·로그인 화면", "진본 시작 화면으로 이동", #selector(returnToWelcome))
            ]))
        }

        stack.addArrangedSubview(sectionTitle("앱 정보"))
        stack.addArrangedSubview(menuCard([
            ("doc.text.magnifyingglass", "오픈소스 라이선스", "사용한 오픈소스와 저작권 정보", #selector(showOpenSourceLicenses))
        ]))
        stack.addArrangedSubview(versionLabel())
    }

    private func profileCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        let avatar = UILabel()
        avatar.text = String((Properties.getMemberName() ?? "진").prefix(1))
        avatar.textAlignment = .center
        avatar.font = .jinBonFont(ofSize: 22, weight: .bold)
        avatar.textColor = .white
        avatar.backgroundColor = ColorPalette.primary
        avatar.layer.cornerRadius = 25
        avatar.clipsToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false

        let name = UILabel()
        name.text = Properties.getMemberName() ?? "로그인이 필요합니다"
        name.font = .jinBonFont(ofSize: 18, weight: .bold)
        name.textColor = ColorPalette.ink
        let role = UILabel()
        role.text = Properties.getMemberRole() == "ISSUER" ? "공인 등록자" : (Properties.getMemberRole() ?? "비회원")
        role.font = .jinBonFont(ofSize: 14, weight: .medium)
        role.textColor = ColorPalette.secondaryText
        let labels = UIStackView(arrangedSubviews: [name, role])
        labels.axis = .vertical
        labels.spacing = 4
        let row = UIStackView(arrangedSubviews: [avatar, labels])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 14
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 50), avatar.heightAnchor.constraint(equalToConstant: 50),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 18), row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18), row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])
        return card
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .jinBonFont(ofSize: 15, weight: .bold)
        label.textColor = ColorPalette.ink
        return label
    }

    private func menuCard(_ items: [(String, String, String, Selector)], destructive: Bool = false) -> UIView {
        let card = UIStackView()
        card.axis = .vertical
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.layer.masksToBounds = true
        for (index, item) in items.enumerated() {
            let button = UIButton(type: .system)
            button.accessibilityIdentifier = "settings.menu.\(item.1)"
            button.contentHorizontalAlignment = .fill
            button.addTarget(self, action: item.3, for: .touchUpInside)
            let icon = UIImageView(image: UIImage(systemName: item.0))
            icon.tintColor = destructive ? ColorPalette.danger : ColorPalette.primary
            icon.translatesAutoresizingMaskIntoConstraints = false
            let title = UILabel(); title.text = item.1; title.font = .jinBonFont(ofSize: 15, weight: .semibold)
            title.textColor = destructive ? ColorPalette.danger : ColorPalette.ink
            let detail = UILabel(); detail.text = item.2; detail.font = .jinBonFont(ofSize: 13); detail.textColor = ColorPalette.secondaryText
            let labels = UIStackView(arrangedSubviews: [title, detail]); labels.axis = .vertical; labels.spacing = 3
            let row = UIStackView(arrangedSubviews: [icon, labels]); row.axis = .horizontal; row.alignment = .center; row.spacing = 13
            row.isUserInteractionEnabled = false
            row.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(row)
            NSLayoutConstraint.activate([
                icon.widthAnchor.constraint(equalToConstant: 23), icon.heightAnchor.constraint(equalToConstant: 23),
                row.topAnchor.constraint(equalTo: button.topAnchor, constant: 15), row.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 17),
                row.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -17), row.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -15),
                button.heightAnchor.constraint(greaterThanOrEqualToConstant: 70)
            ])
            card.addArrangedSubview(button)
            if index < items.count - 1 {
                let divider = UIView(); divider.backgroundColor = ColorPalette.divider
                divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
                card.addArrangedSubview(divider)
            }
        }
        return card
    }

    private func versionLabel() -> UILabel {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        let label = UILabel()
        label.text = "진본 Wallet \(version) (\(build))"
        label.font = .jinBonFont(ofSize: 12, weight: .medium)
        label.textColor = ColorPalette.secondaryText
        label.textAlignment = .center
        label.accessibilityLabel = "진본 Wallet 버전 \(version), 빌드 \(build)"
        return label
    }

    @objc private func showDid() {
        var message = "이 기기에 등록된 디지털 신원이 없습니다."
        if let doc = try? WalletAPI.shared.getDidDocument(type: .HolderDidDocumnet) { message = doc.id }
        showAlert("내 디지털 신원", message)
    }

    @objc private func showWalletSecurity() {
        let storyboard = Storyboard.main.instance
        let settings = storyboard.instantiateViewController(withIdentifier: ViewControllerID.authSetting.rawValue)
        navigationController?.pushViewController(settings, animated: true)
    }

    @objc private func showCertificates() { tabBarController?.selectedIndex = 2 }

    @objc private func openGuestVerification() {
        let verify = VideoVerifyViewController()
        let nav = UINavigationController(rootViewController: verify)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func returnToWelcome() {
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?
            .changeRootVC(JinBonWelcomeViewController(), animated: true)
    }

    @objc private func showOpenSourceLicenses() {
        navigationController?.pushViewController(OpenSourceLicensesViewController(), animated: true)
    }

    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "로그아웃할까요?", message: "Wallet과 인증서는 이 기기에 안전하게 유지됩니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive) { _ in
            Task {
                await JinBonAPIClient.shared.logout()
                await MainActor.run {
                    (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?
                        .changeRootVC(JinBonWelcomeViewController(), animated: true)
                }
            }
        })
        present(alert, animated: true)
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

private final class OpenSourceLicensesViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "오픈소스 라이선스"
        view.backgroundColor = ColorPalette.canvas
        buildUI()
    }

    private func buildUI() {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
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

        stack.addArrangedSubview(makeIntroCard())
        stack.addArrangedSubview(makeSectionTitle("주요 오픈소스"))
        stack.addArrangedSubview(makeComponentCard(
            icon: "building.columns.fill",
            title: "OpenDID DIDCA for iOS",
            detail: "진본 Wallet의 기반 프로젝트",
            copyright: "Copyright 2024 OmniOne.",
            license: "Apache License 2.0"
        ))
        stack.addArrangedSubview(makeComponentCard(
            icon: "wallet.pass.fill",
            title: "OmniOne DID Client SDK",
            detail: "DID·Wallet·VC 기능 · 버전 2.0.1",
            copyright: "OmniOne OpenDID",
            license: "Apache License 2.0"
        ))
        stack.addArrangedSubview(makeComponentCard(
            icon: "square.stack.3d.up.fill",
            title: "Swift Collections",
            detail: "컬렉션 자료구조 · 버전 1.1.4",
            copyright: "Copyright Apple Inc.",
            license: "Apache License 2.0"
        ))
        stack.addArrangedSubview(makeComponentCard(
            icon: "bell.badge.fill",
            title: "Firebase Apple SDK",
            detail: "푸시 알림 및 메시징 · 버전 11.6.0",
            copyright: "Copyright Google LLC",
            license: "Apache License 2.0"
        ))

        stack.addArrangedSubview(makeSectionTitle("문서"))
        stack.addArrangedSubview(makeDocumentCard(
            title: "제3자 고지 전체 보기",
            detail: "출처, 버전, MIT 구성요소를 포함한 상세 고지",
            selector: #selector(showNotices)
        ))
        stack.addArrangedSubview(makeDocumentCard(
            title: "Apache License 2.0 전문",
            detail: "사용·수정·배포 조건과 면책 조항",
            selector: #selector(showApacheLicense)
        ))

        let footnote = UILabel()
        footnote.numberOfLines = 0
        footnote.font = .jinBonFont(ofSize: 12)
        footnote.textColor = ColorPalette.secondaryText
        footnote.setJinBonText(
            "오픈소스 저작권은 각 저작권자에게 있습니다. 진본 서비스에 맞춘 변경 사항은 JinBon 기여자들이 관리합니다.",
            lineSpacing: 4
        )
        stack.addArrangedSubview(footnote)
    }

    private func makeIntroCard() -> UIView {
        let card = UIView()
        card.backgroundColor = ColorPalette.ink
        card.layer.cornerRadius = 22
        card.layer.cornerCurve = .continuous

        let iconBox = UIView()
        iconBox.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        iconBox.layer.cornerRadius = 14
        iconBox.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView(image: UIImage(systemName: "heart.text.square.fill"))
        icon.tintColor = .white
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBox.addSubview(icon)

        let eyebrow = UILabel()
        eyebrow.text = "OPEN SOURCE"
        eyebrow.font = .jinBonFont(ofSize: 12, weight: .bold)
        eyebrow.textColor = ColorPalette.softBlue
        let title = UILabel()
        title.text = "함께 만든 기술을\n투명하게 공개합니다"
        title.numberOfLines = 0
        title.font = .jinBonFont(ofSize: 23, weight: .bold)
        title.textColor = .white
        let detail = UILabel()
        detail.numberOfLines = 0
        detail.font = .jinBonFont(ofSize: 14)
        detail.textColor = UIColor.white.withAlphaComponent(0.8)
        detail.setJinBonText(
            "진본 Wallet은 OmniOne OpenDID 오픈소스를 기반으로 제작되었습니다.",
            lineSpacing: 5
        )
        let textStack = UIStackView(arrangedSubviews: [eyebrow, title, detail])
        textStack.axis = .vertical
        textStack.spacing = 8
        let row = UIStackView(arrangedSubviews: [iconBox, textStack])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 14
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -22),
            iconBox.widthAnchor.constraint(equalToConstant: 48),
            iconBox.heightAnchor.constraint(equalToConstant: 48),
            icon.centerXAnchor.constraint(equalTo: iconBox.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBox.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 23),
            icon.heightAnchor.constraint(equalToConstant: 23)
        ])
        return card
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .jinBonFont(ofSize: 17, weight: .bold)
        label.textColor = ColorPalette.ink
        return label
    }

    private func makeComponentCard(
        icon systemName: String,
        title: String,
        detail: String,
        copyright: String,
        license: String
    ) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.layer.cornerCurve = .continuous

        let iconBox = UIView()
        iconBox.backgroundColor = ColorPalette.softBlue
        iconBox.layer.cornerRadius = 12
        iconBox.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView(image: UIImage(systemName: systemName))
        icon.tintColor = ColorPalette.primary
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBox.addSubview(icon)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .jinBonFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = ColorPalette.ink
        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.font = .jinBonFont(ofSize: 13)
        detailLabel.textColor = ColorPalette.secondaryText
        detailLabel.numberOfLines = 0
        let copyrightLabel = UILabel()
        copyrightLabel.text = copyright
        copyrightLabel.font = .jinBonFont(ofSize: 12)
        copyrightLabel.textColor = ColorPalette.secondaryText
        copyrightLabel.numberOfLines = 0

        let badge = UILabel()
        badge.text = "  \(license)  "
        badge.font = .jinBonFont(ofSize: 11, weight: .bold)
        badge.textColor = ColorPalette.primary
        badge.backgroundColor = ColorPalette.softBlue
        badge.layer.cornerRadius = 10
        badge.clipsToBounds = true
        badge.setContentHuggingPriority(.required, for: .horizontal)

        let metadata = UIStackView(arrangedSubviews: [copyrightLabel, badge])
        metadata.axis = .horizontal
        metadata.alignment = .center
        metadata.spacing = 8
        let labels = UIStackView(arrangedSubviews: [titleLabel, detailLabel, metadata])
        labels.axis = .vertical
        labels.spacing = 5
        let row = UIStackView(arrangedSubviews: [iconBox, labels])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 13
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            iconBox.widthAnchor.constraint(equalToConstant: 42),
            iconBox.heightAnchor.constraint(equalToConstant: 42),
            icon.centerXAnchor.constraint(equalTo: iconBox.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBox.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 21),
            icon.heightAnchor.constraint(equalToConstant: 21)
        ])
        return card
    }

    private func makeDocumentCard(title: String, detail: String, selector: Selector) -> UIView {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 16
        button.contentHorizontalAlignment = .fill
        button.addTarget(self, action: selector, for: .touchUpInside)

        let icon = UIImageView(image: UIImage(systemName: "doc.text"))
        icon.tintColor = ColorPalette.primary
        icon.translatesAutoresizingMaskIntoConstraints = false
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .jinBonFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = ColorPalette.ink
        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.font = .jinBonFont(ofSize: 12)
        detailLabel.textColor = ColorPalette.secondaryText
        detailLabel.numberOfLines = 0
        let labels = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        labels.axis = .vertical
        labels.spacing = 3
        let row = UIStackView(arrangedSubviews: [icon, labels])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isUserInteractionEnabled = false
        row.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: button.topAnchor, constant: 15),
            row.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -15),
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22)
        ])
        return button
    }

    @objc private func showNotices() {
        showDocument(
            title: "제3자 고지",
            resource: "THIRD_PARTY_NOTICES",
            extension: "md",
            fallback: "제3자 고지 문서를 불러오지 못했습니다."
        )
    }

    @objc private func showApacheLicense() {
        showDocument(
            title: "Apache License 2.0",
            resource: "LICENSE",
            extension: nil,
            fallback: "Apache License 2.0 전문을 불러오지 못했습니다."
        )
    }

    private func showDocument(title: String, resource: String, extension fileExtension: String?, fallback: String) {
        let text: String
        if let url = Bundle.main.url(forResource: resource, withExtension: fileExtension),
           let contents = try? String(contentsOf: url, encoding: .utf8) {
            text = contents
        } else {
            text = fallback
        }
        navigationController?.pushViewController(
            LicenseDocumentViewController(title: title, text: text),
            animated: true
        )
    }
}

private final class LicenseDocumentViewController: UIViewController {
    private let documentTitle: String
    private let text: String

    init(title: String, text: String) {
        documentTitle = title
        self.text = text
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = documentTitle
        view.backgroundColor = ColorPalette.canvas

        let textView = UITextView()
        textView.text = text
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = ColorPalette.ink
        textView.backgroundColor = .white
        textView.isEditable = false
        textView.isSelectable = true
        textView.alwaysBounceVertical = true
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 16, bottom: 28, right: 16)
        textView.layer.cornerRadius = 18
        textView.layer.cornerCurve = .continuous
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }
}

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
            button.contentHorizontalAlignment = .fill
            button.addTarget(self, action: item.3, for: .touchUpInside)
            let icon = UIImageView(image: UIImage(systemName: item.0))
            icon.tintColor = destructive ? ColorPalette.danger : ColorPalette.primary
            icon.translatesAutoresizingMaskIntoConstraints = false
            let title = UILabel(); title.text = item.1; title.font = .jinBonFont(ofSize: 15, weight: .semibold)
            title.textColor = destructive ? ColorPalette.danger : ColorPalette.ink
            let detail = UILabel(); detail.text = item.2; detail.font = .jinBonFont(ofSize: 13); detail.textColor = ColorPalette.secondaryText
            let labels = UIStackView(arrangedSubviews: [title, detail]); labels.axis = .vertical; labels.spacing = 3
            let chevron = UIImageView(image: UIImage(systemName: "chevron.right")); chevron.tintColor = ColorPalette.secondaryText
            let row = UIStackView(arrangedSubviews: [icon, labels, chevron]); row.axis = .horizontal; row.alignment = .center; row.spacing = 13
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

import UIKit
import DIDWalletSDK

final class JinBonWelcomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorPalette.canvas
        buildUI()
    }

    private func buildUI() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        let mark = UILabel()
        mark.text = "J"
        mark.textAlignment = .center
        mark.font = .systemFont(ofSize: 30, weight: .black)
        mark.textColor = .white
        mark.backgroundColor = ColorPalette.primary
        mark.layer.cornerRadius = 18
        mark.clipsToBounds = true

        let title = UILabel()
        title.numberOfLines = 0
        title.font = .systemFont(ofSize: 34, weight: .bold)
        title.textColor = ColorPalette.ink
        title.setJinBonText("진짜를 증명하는\n가장 간단한 방법", lineSpacing: 7)

        let subtitle = UILabel()
        subtitle.numberOfLines = 0
        subtitle.font = .systemFont(ofSize: 16, weight: .regular)
        subtitle.textColor = ColorPalette.secondaryText
        subtitle.setJinBonText("영상의 원본 여부를 안전하게 증명하세요.", lineSpacing: 5)

        let signup = actionCard(icon: "person.badge.plus", title: "처음 이용하시나요?",
                                detail: "디지털 신원을 만들고 진본을 시작해요",
                                buttonTitle: "회원가입", primary: true,
                                action: #selector(signupTapped))
        let login = actionCard(icon: "person.crop.circle.badge.checkmark", title: "이미 가입하셨나요?",
                               detail: "모바일 신분증으로 안전하게 로그인해요",
                               buttonTitle: "로그인", primary: false,
                               action: #selector(loginTapped))

        let verify = UIButton(type: .system)
        verify.setTitle("로그인 없이 영상 검증하기  →", for: .normal)
        verify.setTitleColor(ColorPalette.primary, for: .normal)
        verify.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        verify.addTarget(self, action: #selector(verifyTapped), for: .touchUpInside)
        verify.heightAnchor.constraint(equalToConstant: 48).isActive = true

        [mark, title, subtitle, signup, login, verify].forEach(stack.addArrangedSubview)
        stack.setCustomSpacing(24, after: subtitle)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 42),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -28),
            mark.widthAnchor.constraint(equalToConstant: 58),
            mark.heightAnchor.constraint(equalToConstant: 58)
        ])
    }

    private func actionCard(icon: String, title: String, detail: String, buttonTitle: String,
                            primary: Bool, action: Selector) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 22
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowRadius = 18
        card.layer.shadowOffset = CGSize(width: 0, height: 7)

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = ColorPalette.primary
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = ColorPalette.ink

        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.font = .systemFont(ofSize: 14)
        detailLabel.textColor = ColorPalette.secondaryText
        detailLabel.numberOfLines = 0

        let button = UIButton(type: .system)
        button.setTitle(buttonTitle, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.layer.cornerRadius = 13
        button.backgroundColor = primary ? ColorPalette.primary : ColorPalette.primary.withAlphaComponent(0.09)
        button.setTitleColor(primary ? .white : ColorPalette.primary, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)

        [iconView, titleLabel, detailLabel, button].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview($0)
        }
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            titleLabel.topAnchor.constraint(equalTo: iconView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            button.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 18),
            button.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            button.heightAnchor.constraint(equalToConstant: 50),
            button.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
        return card
    }

    @objc private func signupTapped() { presentAuth(.signup) }
    @objc private func loginTapped() { presentAuth(.login) }
    @objc private func verifyTapped() {
        let verify = VideoVerifyViewController()
        verify.showsCloseButton = true
        let nav = UINavigationController(rootViewController: verify)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func presentAuth(_ mode: AuthWebViewController.Mode) {
        let auth = AuthWebViewController()
        auth.mode = mode
        auth.delegate = self
        let nav = UINavigationController(rootViewController: auth)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func switchToMain() {
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?
            .changeRootVC(JinBonTabBarController(), animated: true)
    }
}

extension JinBonWelcomeViewController: AuthWebViewDelegate {
    func authDidComplete(tokenData: AuthTokenData) {
        switch WalletAccountValidator.validate(accountDid: tokenData.did) {
        case .matches:
            switchToMain()
        case .noWallet:
            guard let rebindToken = tokenData.didRebindToken else {
                JinBonAPIClient.shared.clearLocalSession()
                showRecoveryError("DID 재연결 토큰을 발급받지 못했습니다. 모바일 신분증으로 다시 로그인해주세요.")
                return
            }
            Properties.setDidRebindToken(rebindToken)
            showDidRecovery()
        case .mismatch:
            JinBonAPIClient.shared.clearLocalSession()
            showRecoveryError("이 기기의 Wallet DID가 로그인한 진본 계정의 DID와 다릅니다. 다른 계정의 Wallet을 연결할 수 없습니다.")
        case .accountDidMissing:
            JinBonAPIClient.shared.clearLocalSession()
            showRecoveryError("진본 계정에 연결된 DID가 없습니다. 디지털 신원 재연결이 필요합니다.")
        }
    }
    func authDidCancel() {}

    func signupIdentityDidComplete(data: SignupIdentityData) {
        if WalletAPI.shared.isExistWallet() {
            confirmExistingDidConnection()
        } else {
            showDidRegistration()
        }
    }

    private func confirmExistingDidConnection() {
        let alert = UIAlertController(
            title: "기존 Wallet을 연결할까요?",
            message: "이 기기에 이미 디지털 신원이 있습니다. 본인의 Wallet이 맞을 때만 새 진본 계정에 연결해주세요.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "내 Wallet 연결", style: .default) { [weak self] _ in
            self?.connectExistingDid()
        })
        present(alert, animated: true)
    }

    private func connectExistingDid() {
        Task { @MainActor in
            guard let didDoc = try? WalletAPI.shared.getDidDocument(type: .HolderDidDocumnet),
                  let signupToken = Properties.getSignupToken() else {
                showRecoveryError("기존 Wallet 정보를 확인할 수 없습니다.")
                return
            }
            do {
                _ = try await JinBonAPIClient.shared.completeSignup(signupToken: signupToken, did: didDoc.id)
                Properties.setRegDidDocCompleted(status: true)
                Properties.clearSignupToken()
                switchToMain()
            } catch {
                showRecoveryError(error.localizedDescription)
            }
        }
    }

    private func showDidRegistration() {
        let step = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "StepViewController") as! StepViewController
        step.setStepType(stepType: Properties.getUserId() == nil ? .STEP_TYPE_1 : .STEP_TYPE_2)
        step.modalPresentationStyle = .fullScreen
        present(step, animated: true)
    }

    private func showDidRecovery() {
        let alert = UIAlertController(
            title: "디지털 신원을 다시 연결할까요?",
            message: "이 기기에 DID가 없습니다. 새 DID를 만든 뒤 기존 진본 계정에 안전하게 연결합니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "나중에", style: .cancel))
        alert.addAction(UIAlertAction(title: "다시 연결", style: .default) { [weak self] _ in
            self?.showDidRegistration()
        })
        present(alert, animated: true)
    }

    private func showRecoveryError(_ message: String) {
        let alert = UIAlertController(title: "디지털 신원 연결 실패", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

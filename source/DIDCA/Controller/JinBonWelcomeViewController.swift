import UIKit
import DIDWalletSDK

final class JinBonWelcomeViewController: UIViewController {
    private var isRebinding = false
    var initialAuthMode: AuthWebViewController.Mode?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let mode = initialAuthMode {
            initialAuthMode = nil
            presentAuth(mode)
        }
    }

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
        mark.font = .jinBonFont(ofSize: 30, weight: .black)
        mark.textColor = .white
        mark.backgroundColor = ColorPalette.primary
        mark.layer.cornerRadius = 18
        mark.clipsToBounds = true

        let title = UILabel()
        title.numberOfLines = 0
        title.font = .jinBonFont(ofSize: 34, weight: .bold)
        title.textColor = ColorPalette.ink
        title.setJinBonText("진짜를 증명하는\n가장 간단한 방법", lineSpacing: 7)

        let subtitle = UILabel()
        subtitle.numberOfLines = 0
        subtitle.font = .jinBonFont(ofSize: 16, weight: .regular)
        subtitle.textColor = ColorPalette.secondaryText
        subtitle.setJinBonText("모바일 신분증 기반 공인 영상 진본 증명 플랫폼.\n발표 영상의 확인 기준을 남기세요.", lineSpacing: 5)

        let signup = actionCard(icon: "person.badge.plus", title: "처음 이용하시나요?",
                                detail: "모바일 신분증으로 본인확인하고 공인 등록자로 시작해요",
                                buttonTitle: "회원가입", primary: true,
                                action: #selector(signupTapped))
        let login = actionCard(icon: "person.crop.circle.badge.checkmark", title: "이미 가입하셨나요?",
                               detail: "모바일 신분증으로 안전하게 로그인해요",
                               buttonTitle: "로그인", primary: false,
                               action: #selector(loginTapped))

        let verify = PressFeedbackButton(type: .system)
        verify.setTitle("로그인 없이 영상 검증하기  →", for: .normal)
        verify.accessibilityIdentifier = "welcome.verify"
        verify.setTitleColor(ColorPalette.primary, for: .normal)
        verify.titleLabel?.font = .jinBonFont(ofSize: 15, weight: .semibold)
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
        titleLabel.font = .jinBonFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = ColorPalette.ink

        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.font = .jinBonFont(ofSize: 14)
        detailLabel.textColor = ColorPalette.secondaryText
        detailLabel.numberOfLines = 0

        let button = PressFeedbackButton(type: .system)
        button.setTitle(buttonTitle, for: .normal)
        button.accessibilityIdentifier = primary ? "welcome.signup" : "welcome.login"
        button.titleLabel?.font = .jinBonFont(ofSize: 16, weight: .bold)
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

    private func unlockWalletIfNeeded(completion: @escaping () -> Void) {
        guard WalletAPI.shared.isExistWallet(),
              (try? WalletAPI.shared.isLock()) == true else {
            completion()
            return
        }

        let pinVC = Storyboard.pin.instance
            .instantiateViewController(withIdentifier: ViewControllerID.pincode.rawValue) as! PincodeViewController
        pinVC.modalPresentationStyle = .fullScreen
        pinVC.setRequestType(type: .authenticate(isLock: true))
        pinVC.confirmButtonCompleteClosure = { _ in
            completion()
        }
        pinVC.cancelButtonCompleteClosure = { [weak self] in
            guard let self else { return }
            JinBonAPIClient.shared.clearLocalSession()
            PopupUtils.showAlertPopup(
                title: "Notification",
                content: "PIN authentication is required to use this Wallet.",
                VC: self
            )
        }
        present(pinVC, animated: false)
    }

    private func continueLogin(with tokenData: AuthTokenData) {
        switch WalletAccountValidator.validate(accountDid: tokenData.did) {
        case .matches:
            JinBonAPIClient.shared.saveSession(tokenData)
            Properties.setRegDidDocCompleted(status: true)
            switchToMain()
        case .noWallet:
            guard let rebindToken = tokenData.didRebindToken else {
                JinBonAPIClient.shared.clearLocalSession()
                showRecoveryError("DID 재연결 토큰을 발급받지 못했습니다. 모바일 신분증으로 다시 로그인해주세요.")
                return
            }
            Properties.setDidRebindToken(rebindToken)
            showDidRecovery()
        case .mismatch, .accountDidMissing:
            guard let rebindToken = tokenData.didRebindToken else {
                JinBonAPIClient.shared.clearLocalSession()
                showRecoveryError("DID 재연결 토큰을 발급받지 못했습니다. 모바일 신분증으로 다시 로그인해주세요.")
                return
            }
            confirmWalletRebind(rebindToken: rebindToken)
        }
    }
}

extension JinBonWelcomeViewController: AuthWebViewDelegate {
    func authDidComplete(tokenData: AuthTokenData) {
        unlockWalletIfNeeded { [weak self] in
            self?.continueLogin(with: tokenData)
        }
    }
    func authDidCancel() {}

    func signupIdentityDidComplete(data: SignupIdentityData) {
        unlockWalletIfNeeded { [weak self] in
            guard let self else { return }
            if WalletAccountValidator.hasHolderDid() {
                self.confirmExistingDidConnection()
            } else {
                self.showDidRegistration()
            }
        }
    }

    private func confirmExistingDidConnection() {
        let popup = Storyboard.popup.instance
            .instantiateViewController(withIdentifier: ViewControllerID.twoButtonDialog.rawValue) as! TwoButtonDialogViewController
        popup.modalPresentationStyle = .overCurrentContext
        popup.configure(
            title: "기존 Wallet을 연결할까요?",
            message: "이 기기에 이미 디지털 신원이 있습니다. 본인의 Wallet이 맞을 때만 새 진본 계정에 연결해주세요.",
            cancelTitle: "연결 안 함",
            confirmTitle: "내 Wallet 연결"
        )
        popup.cancelButtonCompleteClosure = { [weak self] in
            self?.confirmDiscardExistingWallet()
        }
        popup.confirmButtonCompleteClosure = { [weak self] in
            self?.connectExistingDid()
        }
        present(popup, animated: false)
    }

    /// 기기에 남아 있는 Wallet을 지우고 새로 만든다.
    /// 키체인에 저장되는 값이라 앱을 지워도 남기 때문에, 이 경로로만 초기화할 수 있다.
    private func confirmDiscardExistingWallet() {
        let popup = Storyboard.popup.instance
            .instantiateViewController(withIdentifier: ViewControllerID.twoButtonDialog.rawValue) as! TwoButtonDialogViewController
        popup.modalPresentationStyle = .overCurrentContext
        popup.configure(
            title: "기존 Wallet을 폐기할까요?",
            message: "이 기기의 디지털 신원과 보유한 증명서가 모두 삭제되며 되돌릴 수 없습니다. 삭제 후 새 신원을 발급받습니다.",
            cancelTitle: "취소",
            confirmTitle: "폐기하고 새로 만들기"
        )
        popup.confirmButtonCompleteClosure = { [weak self] in
            self?.discardExistingWallet()
        }
        present(popup, animated: false)
    }

    private func discardExistingWallet() {
        Task { @MainActor in
            do {
                try WalletAPI.shared.deleteWallet(deleteAll: true)
                // Splash와 동일하게 빈 Wallet을 다시 만들어야 이후 DID 등록이 진행된다.
                _ = try await WalletAPI.shared.createWallet(tasURL: URLs.TAS_URL,
                                                           walletURL: URLs.WALLET_URL)
                showDidRegistration()
            } catch {
                let (_, message) = ErrorHandler.handle(error)
                showRecoveryError(message)
            }
        }
    }

    private func connectExistingDid() {
        Task { @MainActor in
            guard let didDoc = try? WalletAPI.shared.getDidDocument(type: .HolderDidDocumnet),
                  let signupToken = Properties.getSignupToken() else {
                showRecoveryError("기존 Wallet 정보를 확인할 수 없습니다.")
                return
            }
            do {
                try await JinBonAPIClient.shared.completeSignup(signupToken: signupToken, did: didDoc.id)
                Properties.setRegDidDocCompleted(status: true)
                Properties.clearSignupToken()
                let alert = UIAlertController(title: "회원가입 완료", message: "회원가입이 완료되었습니다. 로그인해 주세요.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                present(alert, animated: true)
            } catch {
                showRecoveryError(error.localizedDescription)
            }
        }
    }

    private func showDidRegistration() {
        let step = Storyboard.main.instance
            .instantiateViewController(withIdentifier: ViewControllerID.stepVC.rawValue) as! StepViewController
        step.setStepType(stepType: Properties.getUserId() == nil ? .STEP_TYPE_1 : .STEP_TYPE_2)
        step.modalPresentationStyle = .fullScreen
        present(step, animated: true)
    }

    private func showDidRecovery() {
        let alert = UIAlertController(
            title: "새 디지털 신원을 연결할까요?",
            message: "이 기기에 기존 Wallet이 없습니다. 새 신원을 연결하면 기존 계정의 DID가 변경됩니다. 기존 영상의 등록 기록은 유지되지만, 이전 Wallet의 보증서는 복구되지 않으며 기존 영상의 보증서 발급에는 이전 Wallet이 필요합니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
            JinBonAPIClient.shared.clearLocalSession()
        })
        alert.addAction(UIAlertAction(title: "새 신원 연결", style: .default) { [weak self] _ in
            self?.showDidRegistration()
        })
        present(alert, animated: true)
    }

    private func confirmWalletRebind(rebindToken: String) {
        let popup = Storyboard.popup.instance
            .instantiateViewController(withIdentifier: ViewControllerID.twoButtonDialog.rawValue) as! TwoButtonDialogViewController
        popup.modalPresentationStyle = .overCurrentContext
        popup.configure(
            title: "디지털 신원 다시 연결",
            message: "계정과 이 기기의 DID가 다릅니다. 연결하면 계정의 DID가 변경됩니다. 기존 보증서는 이 Wallet으로 이전되지 않으며, 기존 영상의 보증서 발급에는 이전 Wallet이 필요합니다. 본인의 Wallet인지 확인해 주세요.",
            cancelTitle: "취소",
            confirmTitle: "다시 연결"
        )
        popup.cancelButtonCompleteClosure = {
            JinBonAPIClient.shared.clearLocalSession()
        }
        popup.confirmButtonCompleteClosure = { [weak self] in
            self?.rebindCurrentWallet(using: rebindToken)
        }
        present(popup, animated: false)
    }

    private func rebindCurrentWallet(using rebindToken: String) {
        guard !isRebinding else { return }
        isRebinding = true
        Task { @MainActor in
            guard let didDoc = try? WalletAPI.shared.getDidDocument(type: .HolderDidDocumnet),
                  !didDoc.id.isEmpty else {
                isRebinding = false
                JinBonAPIClient.shared.clearLocalSession()
                showRecoveryError("현재 Wallet의 디지털 신원을 확인할 수 없습니다.")
                return
            }
            do {
                _ = try await JinBonAPIClient.shared.rebindDid(
                    didRebindToken: rebindToken,
                    did: didDoc.id
                )
                Properties.setRegDidDocCompleted(status: true)
                Properties.clearDidRebindToken()
                switchToMain()
            } catch {
                isRebinding = false
                JinBonAPIClient.shared.clearLocalSession()
                showRecoveryError(error.localizedDescription)
            }
        }
    }

    private func showRecoveryError(_ message: String) {
        PopupUtils.showAlertPopup(
            title: "디지털 신원 연결 실패",
            content: message,
            VC: self
        )
    }
}

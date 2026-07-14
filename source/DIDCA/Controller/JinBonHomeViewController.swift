import UIKit

final class JinBonHomeViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let recentStack = UIStackView()
    private let summaryLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "홈"
        view.backgroundColor = ColorPalette.canvas
        configureNavigationBar()
        buildUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshDashboard()
    }

    private func configureNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ColorPalette.canvas
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: ColorPalette.ink]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 18
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 18),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32)
        ])

        contentStack.addArrangedSubview(makeHeader())
        contentStack.addArrangedSubview(makeIdentityCard())
        contentStack.addArrangedSubview(makeRegisterCard())
        contentStack.addArrangedSubview(makeRecentSection())
        contentStack.addArrangedSubview(makeVerifyTool())
    }

    private func makeHeader() -> UIView {
        let container = UIView()
        let eyebrow = UILabel()
        eyebrow.text = "진본 크리에이터 월렛"
        eyebrow.font = .systemFont(ofSize: 13, weight: .bold)
        eyebrow.textColor = ColorPalette.primary

        let title = UILabel()
        let name = Properties.getMemberName() ?? "등록자"
        title.text = "안녕하세요, \(name)님"
        title.font = .systemFont(ofSize: 28, weight: .bold)
        title.textColor = ColorPalette.ink

        let detail = UILabel()
        detail.text = "원본 영상과 인증서를 한곳에서 관리하세요."
        detail.numberOfLines = 0
        detail.font = .systemFont(ofSize: 15)
        detail.textColor = ColorPalette.secondaryText

        let stack = UIStackView(arrangedSubviews: [eyebrow, title, detail])
        stack.axis = .vertical
        stack.spacing = 7
        pin(stack, to: container)
        return container
    }

    private func makeIdentityCard() -> UIView {
        let card = baseCard(background: ColorPalette.ink)
        let icon = iconBox(systemName: "checkmark.seal.fill", tint: .white,
                           background: UIColor.white.withAlphaComponent(0.14))

        let title = UILabel()
        title.text = Properties.isLoggedIn() ? "디지털 신원 연결됨" : "로그인이 필요합니다"
        title.font = .systemFont(ofSize: 17, weight: .bold)
        title.textColor = .white

        let role = Properties.getMemberRole() ?? "GUEST"
        let subtitle = UILabel()
        subtitle.text = role == "ISSUER" ? "공인 등록자 · 영상 등록 가능" : "\(role) · 등록 권한 확인 필요"
        subtitle.font = .systemFont(ofSize: 14, weight: .medium)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.86)

        let labels = UIStackView(arrangedSubviews: [title, subtitle])
        labels.axis = .vertical
        labels.spacing = 4

        let row = UIStackView(arrangedSubviews: [icon, labels])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 14
        pin(row, to: card, insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
        return card
    }

    private func makeRegisterCard() -> UIView {
        let card = baseCard(background: ColorPalette.primary)
        let title = UILabel()
        title.text = "새 원본 영상 등록"
        title.font = .systemFont(ofSize: 22, weight: .bold)
        title.textColor = .white

        let body = UILabel()
        body.text = "영상의 해시를 블록체인에 기록해요."
        body.numberOfLines = 0
        body.font = .systemFont(ofSize: 14)
        body.textColor = UIColor.white.withAlphaComponent(0.9)

        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "영상 등록하기"
        config.image = UIImage(systemName: "arrow.up.circle.fill")
        config.imagePadding = 8
        config.baseBackgroundColor = .white
        config.baseForegroundColor = ColorPalette.primary
        config.cornerStyle = .large
        button.configuration = config
        button.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let stack = UIStackView(arrangedSubviews: [title, body, button])
        stack.axis = .vertical
        stack.spacing = 14
        pin(stack, to: card, insets: UIEdgeInsets(top: 24, left: 22, bottom: 22, right: 22))
        return card
    }

    private func makeRecentSection() -> UIView {
        let container = UIView()
        let title = UILabel()
        title.text = "최근 등록"
        title.font = .systemFont(ofSize: 19, weight: .bold)
        title.textColor = ColorPalette.ink

        summaryLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        summaryLabel.textColor = ColorPalette.secondaryText
        summaryLabel.textAlignment = .right

        let header = UIStackView(arrangedSubviews: [title, summaryLabel])
        header.axis = .horizontal
        header.distribution = .equalSpacing

        recentStack.axis = .vertical
        recentStack.spacing = 10

        let stack = UIStackView(arrangedSubviews: [header, recentStack])
        stack.axis = .vertical
        stack.spacing = 12
        pin(stack, to: container)
        return container
    }

    private func makeVerifyTool() -> UIView {
        let card = baseCard(background: .white)
        card.layer.borderWidth = 1
        card.layer.borderColor = ColorPalette.divider.cgColor

        let icon = iconBox(systemName: "checkmark.shield", tint: ColorPalette.primary,
                           background: ColorPalette.softBlue)
        let title = UILabel()
        title.text = "영상 검증 도구"
        title.font = .systemFont(ofSize: 15, weight: .bold)
        title.textColor = ColorPalette.ink

        let detail = UILabel()
        detail.text = "영상이 진본으로 등록됐는지 확인"
        detail.font = .systemFont(ofSize: 14)
        detail.textColor = ColorPalette.secondaryText
        detail.numberOfLines = 0

        let labels = UIStackView(arrangedSubviews: [title, detail])
        labels.axis = .vertical
        labels.spacing = 4

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = ColorPalette.secondaryText
        let row = UIStackView(arrangedSubviews: [icon, labels, chevron])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        pin(row, to: card, insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(verifyTapped)))
        return card
    }

    private func refreshDashboard() {
        Task {
            guard Properties.isLoggedIn() else {
                await MainActor.run { self.showRecent([]) }
                return
            }
            do {
                let videos = try await JinBonAPIClient.shared.getMyVideos()
                await MainActor.run { self.showRecent(videos) }
            } catch {
                await MainActor.run { self.showRecent([]) }
            }
        }
    }

    private func showRecent(_ videos: [VideoDetailData]) {
        recentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        summaryLabel.text = videos.isEmpty ? "" : "총 \(videos.count)건"
        if videos.isEmpty {
            let empty = UILabel()
            empty.text = Properties.isLoggedIn() ? "아직 등록한 영상이 없습니다." : "로그인 후 등록 현황을 확인할 수 있습니다."
            empty.font = .systemFont(ofSize: 14)
            empty.textColor = ColorPalette.secondaryText
            empty.textAlignment = .center
            let card = baseCard(background: .white)
            pin(empty, to: card, insets: UIEdgeInsets(top: 28, left: 16, bottom: 28, right: 16))
            recentStack.addArrangedSubview(card)
            return
        }
        videos.prefix(3).forEach { recentStack.addArrangedSubview(makeVideoRow($0)) }
    }

    private func makeVideoRow(_ video: VideoDetailData) -> UIView {
        let card = baseCard(background: .white)
        let icon = iconBox(systemName: "video.fill", tint: ColorPalette.primary,
                           background: ColorPalette.softBlue)
        let title = UILabel()
        title.text = video.title
        title.font = .systemFont(ofSize: 15, weight: .semibold)
        title.textColor = ColorPalette.ink
        let date = UILabel()
        date.text = video.registeredAt.map { String($0.prefix(10)) } ?? "등록일 확인 중"
        date.font = .systemFont(ofSize: 13)
        date.textColor = ColorPalette.secondaryText
        let labels = UIStackView(arrangedSubviews: [title, date])
        labels.axis = .vertical
        labels.spacing = 4
        let badge = UILabel()
        badge.text = video.active == false ? "취소" : "인증 유효"
        badge.font = .systemFont(ofSize: 13, weight: .bold)
        badge.textColor = video.active == false ? ColorPalette.danger : ColorPalette.success
        let row = UIStackView(arrangedSubviews: [icon, labels, badge])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        pin(row, to: card, insets: UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))
        return card
    }

    @objc private func registerTapped() {
        guard Properties.isLoggedIn() else { showMessage("로그인이 필요합니다", "회원가입 또는 로그인 후 영상을 등록할 수 있습니다."); return }
        guard Properties.getMemberRole() == "ISSUER" else { showMessage("등록 권한이 없습니다", "공인 등록자 승인이 완료된 계정만 영상을 등록할 수 있습니다."); return }
        let upload = VideoUploadViewController()
        let nav = UINavigationController(rootViewController: upload)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func verifyTapped() {
        let verify = VideoVerifyViewController()
        let nav = UINavigationController(rootViewController: verify)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func showMessage(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func baseCard(background: UIColor) -> UIView {
        let view = UIView()
        view.backgroundColor = background
        view.layer.cornerRadius = 20
        view.layer.cornerCurve = .continuous
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.04
        view.layer.shadowRadius = 14
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        return view
    }

    private func iconBox(systemName: String, tint: UIColor, background: UIColor) -> UIView {
        let box = UIView()
        box.backgroundColor = background
        box.layer.cornerRadius = 12
        box.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImageView(image: UIImage(systemName: systemName))
        image.tintColor = tint
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(image)
        NSLayoutConstraint.activate([
            box.widthAnchor.constraint(equalToConstant: 46), box.heightAnchor.constraint(equalToConstant: 46),
            image.centerXAnchor.constraint(equalTo: box.centerXAnchor), image.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            image.widthAnchor.constraint(equalToConstant: 22), image.heightAnchor.constraint(equalToConstant: 22)
        ])
        return box
    }

    private func pin(_ child: UIView, to parent: UIView, insets: UIEdgeInsets = .zero) {
        child.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(child)
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: parent.topAnchor, constant: insets.top),
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: insets.left),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -insets.right),
            child.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -insets.bottom)
        ])
    }
}

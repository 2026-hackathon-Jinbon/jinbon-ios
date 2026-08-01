/*
 * Copyright 2025 JinBon.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIKit
import DIDWalletSDK
import AVKit

class VideoListViewController: UIViewController {

    // MARK: - UI

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let stateIcon = UIImageView()
    private let retryButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let loginPromptView = UIView()

    private var videos: [VideoDetailData] = []
    private var isLoggedIn: Bool { Properties.isLoggedIn() }
    private var tableTopToPrompt: NSLayoutConstraint!
    private var tableTopToSafeArea: NSLayoutConstraint!
    private var loadTask: Task<Void, Never>?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorPalette.canvas
        title = "내 영상"

        setupNavigationBar()
        setupLoginPromptView()
        setupTableView()
        setupStateView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ColorPalette.canvas
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: ColorPalette.ink]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = ColorPalette.primary
    }

    private func setupLoginPromptView() {
        loginPromptView.translatesAutoresizingMaskIntoConstraints = false
        loginPromptView.backgroundColor = .white
        loginPromptView.layer.cornerRadius = 18
        view.addSubview(loginPromptView)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "로그인하고 내 영상을 관리하세요"
        titleLabel.font = .jinBonFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = ColorPalette.ink
        titleLabel.textAlignment = .center

        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        let signupBtn = makeActionButton(title: "회원가입", action: #selector(signupTapped))
        let loginBtn = makeActionButton(title: "로그인", action: #selector(loginTapped))
        loginBtn.backgroundColor = ColorPalette.primary
        loginBtn.setTitleColor(.white, for: .normal)

        buttonStack.addArrangedSubview(signupBtn)
        buttonStack.addArrangedSubview(loginBtn)
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(buttonStack)

        loginPromptView.addSubview(stack)

        NSLayoutConstraint.activate([
            loginPromptView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            loginPromptView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            loginPromptView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            stack.topAnchor.constraint(equalTo: loginPromptView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: loginPromptView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: loginPromptView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: loginPromptView.bottomAnchor, constant: -16),

            buttonStack.widthAnchor.constraint(equalTo: stack.widthAnchor),
            buttonStack.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(VideoTableViewCell.self, forCellReuseIdentifier: CellID.videoCell.rawValue)
        tableView.separatorStyle = .none
        tableView.backgroundColor = ColorPalette.canvas
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = ColorPalette.primary
        refreshControl.addTarget(self, action: #selector(refreshVideos), for: .valueChanged)
        tableView.refreshControl = refreshControl
        view.addSubview(tableView)

        tableTopToPrompt = tableView.topAnchor.constraint(equalTo: loginPromptView.bottomAnchor, constant: 8)
        tableTopToSafeArea = tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        tableTopToSafeArea.isActive = false

        NSLayoutConstraint.activate([
            tableTopToPrompt,
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupStateView() {
        stateIcon.image = UIImage(systemName: "video.slash")
        stateIcon.tintColor = ColorPalette.primary
        stateIcon.contentMode = .scaleAspectFit
        stateIcon.translatesAutoresizingMaskIntoConstraints = false

        emptyLabel.numberOfLines = 0
        emptyLabel.textColor = ColorPalette.secondaryText
        emptyLabel.font = .jinBonFont(ofSize: 15)
        emptyLabel.textAlignment = .center
        emptyLabel.setJinBonText("아직 등록한 영상이 없습니다\n홈에서 첫 원본 영상을 등록해 보세요.", lineSpacing: 5)

        var retryConfiguration = UIButton.Configuration.filled()
        retryConfiguration.title = "다시 시도"
        retryConfiguration.image = UIImage(systemName: "arrow.clockwise")
        retryConfiguration.imagePadding = 7
        retryConfiguration.baseBackgroundColor = ColorPalette.primary
        retryConfiguration.cornerStyle = .large
        retryButton.configuration = retryConfiguration
        retryButton.addTarget(self, action: #selector(retryLoad), for: .touchUpInside)
        retryButton.isHidden = true

        loadingIndicator.color = ColorPalette.primary

        let stateStack = UIStackView(arrangedSubviews: [
            loadingIndicator, stateIcon, emptyLabel, retryButton
        ])
        stateStack.axis = .vertical
        stateStack.alignment = .center
        stateStack.spacing = 12
        stateStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stateStack)

        NSLayoutConstraint.activate([
            stateStack.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            stateStack.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: -24),
            stateStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 30),
            stateStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -30),
            stateIcon.widthAnchor.constraint(equalToConstant: 42),
            stateIcon.heightAnchor.constraint(equalToConstant: 42),
            retryButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func makeActionButton(title: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .jinBonFont(ofSize: 14, weight: .semibold)
        btn.layer.cornerRadius = 8
        btn.layer.borderWidth = 1
        btn.layer.borderColor = ColorPalette.primary.cgColor
        btn.setTitleColor(ColorPalette.primary, for: .normal)
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }

    // MARK: - Actions

    @objc private func signupTapped() {
        let authVC = AuthWebViewController()
        authVC.mode = .signup
        authVC.delegate = self
        let nav = UINavigationController(rootViewController: authVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func loginTapped() {
        let authVC = AuthWebViewController()
        authVC.delegate = self
        let nav = UINavigationController(rootViewController: authVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func uploadTapped() {
        let uploadVC = VideoUploadViewController()
        let nav = UINavigationController(rootViewController: uploadVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "로그아웃", message: "로그아웃 하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive) { [weak self] _ in
            Task {
                await JinBonAPIClient.shared.logout()
                DispatchQueue.main.async {
                    self?.updateUI()
                }
            }
        })
        present(alert, animated: true)
    }

    // MARK: - Update UI

    private func updateUI() {
        if isLoggedIn {
            loginPromptView.isHidden = true

            // 로그인 상태: 테이블뷰를 상단으로 올림
            tableTopToPrompt.isActive = false
            tableTopToSafeArea.isActive = true

            // 네비게이션 버튼
            navigationItem.leftBarButtonItem = nil

            let uploadItem = UIBarButtonItem(
                barButtonSystemItem: .add,
                target: self,
                action: #selector(uploadTapped)
            )
            navigationItem.rightBarButtonItems = [uploadItem]
            uploadItem.accessibilityLabel = "새 원본 영상 등록"

            loadVideos()
        } else {
            loginPromptView.isHidden = false
            tableTopToSafeArea.isActive = false
            tableTopToPrompt.isActive = true
            navigationItem.leftBarButtonItem = nil

            navigationItem.rightBarButtonItems = nil

            videos = []
            tableView.reloadData()
            setState(.hidden)
        }
    }

    private func loadVideos(showLoading: Bool = true) {
        loadTask?.cancel()
        if showLoading, videos.isEmpty { setState(.loading) }
        loadTask = Task {
            do {
                let result = try await JinBonAPIClient.shared.getMyVideos()
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.tableView.refreshControl?.endRefreshing()
                    self.videos = result
                    self.tableView.reloadData()
                    self.setState(result.isEmpty ? .empty : .hidden)
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.tableView.refreshControl?.endRefreshing()
                    if case JinBonError.notAuthenticated = error {
                        self.updateUI()
                        return
                    }
                    self.setState(.error(error.localizedDescription))
                }
            }
        }
    }

    @objc private func refreshVideos() {
        loadVideos(showLoading: false)
    }

    @objc private func retryLoad() {
        loadVideos()
    }

    private enum ContentState {
        case hidden
        case loading
        case empty
        case error(String)
    }

    private func setState(_ state: ContentState) {
        loadingIndicator.stopAnimating()
        stateIcon.isHidden = false
        emptyLabel.isHidden = false
        retryButton.isHidden = true
        switch state {
        case .hidden:
            stateIcon.isHidden = true
            emptyLabel.isHidden = true
        case .loading:
            loadingIndicator.startAnimating()
            stateIcon.isHidden = true
            emptyLabel.text = "영상 목록을 불러오는 중입니다"
        case .empty:
            stateIcon.image = UIImage(systemName: "video.slash")
            emptyLabel.setJinBonText(
                "아직 등록한 영상이 없습니다\n홈에서 첫 원본 영상을 등록해 보세요.",
                lineSpacing: 5
            )
        case .error(let message):
            stateIcon.image = UIImage(systemName: "wifi.exclamationmark")
            emptyLabel.setJinBonText(
                "영상 목록을 불러오지 못했습니다\n\(message)",
                lineSpacing: 5
            )
            retryButton.isHidden = false
        }
    }
}

// MARK: - UITableView

extension VideoListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellID.videoCell.rawValue, for: indexPath) as! VideoTableViewCell
        cell.configure(with: videos[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 92
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let video = videos[indexPath.row]

        let status = video.active == false ? "비활성" : "인증 유효"
        let detail = UIAlertController(title: video.title, message: """
        상태: \(status)
        Tx Hash: \(video.txHash ?? "-")
        Block: \(video.blockNumber ?? "-")
        VC ID: \(video.vcId ?? "-")
        등록일: \(video.registeredAt ?? "-")
        """, preferredStyle: .alert)

        if video.active != false {
            detail.addAction(UIAlertAction(title: "영상 비활성화", style: .destructive) { [weak self] _ in
                self?.confirmDeactivation(video)
            })
        }
        if video.active != false, video.vcIssuanceStatus != "ISSUED" {
            detail.addAction(UIAlertAction(title: "Wallet 인증서 발급", style: .default) { [weak self] _ in
                self?.prepareVcIssuance(for: video)
            })
        }
        if let videoURL = JinBonVideoStore.videoURL(videoId: video.videoId) {
            detail.addAction(UIAlertAction(title: "영상 재생", style: .default) { [weak self] _ in
                self?.playVideo(at: videoURL)
            })
        }
        detail.addAction(UIAlertAction(title: "확인", style: .default))
        present(detail, animated: true)
    }

    private func prepareVcIssuance(for video: VideoDetailData) {
        let progress = UIAlertController(
            title: "인증서 발급 준비 중",
            message: "안전한 발급 정보를 확인하고 있어요.",
            preferredStyle: .alert
        )
        present(progress, animated: true)

        Task { @MainActor [weak self, weak progress] in
            guard let self else { return }
            do {
                let result = try await JinBonAPIClient.shared.prepareVideoVc(videoId: video.videoId)
                progress?.dismiss(animated: true) { [weak self] in
                    guard let self else { return }
                    let upload = VideoUploadViewController()
                    upload.resumeVcIssuance(with: result)
                    let navigation = UINavigationController(rootViewController: upload)
                    navigation.modalPresentationStyle = .fullScreen
                    self.present(navigation, animated: true)
                }
            } catch {
                progress?.dismiss(animated: true) { [weak self] in
                    let alert = UIAlertController(
                        title: "인증서 발급을 준비하지 못했습니다",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }

    private func playVideo(at url: URL) {
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        present(playerViewController, animated: true) {
            player.play()
        }
    }

    private func confirmDeactivation(_ video: VideoDetailData) {
        let alert = UIAlertController(
            title: "영상을 비활성화할까요?",
            message: "비활성화 기록은 블록체인에 남으며 되돌릴 수 없습니다. 이후 이 영상은 유효한 진본 영상으로 검증되지 않습니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "비활성화", style: .destructive) { [weak self] _ in
            self?.deactivate(video)
        })
        present(alert, animated: true)
    }

    private func deactivate(_ video: VideoDetailData) {
        let progress = UIAlertController(
            title: "비활성화 처리 중",
            message: "블록체인에 기록하고 있어요. 잠시만 기다려주세요.",
            preferredStyle: .alert
        )
        present(progress, animated: true)

        Task { @MainActor [weak self, weak progress] in
            guard let self else { return }
            do {
                try await JinBonAPIClient.shared.deactivateVideo(videoId: video.videoId)
                progress?.dismiss(animated: true) { [weak self] in
                    guard let self else { return }
                    let done = UIAlertController(
                        title: "비활성화 완료",
                        message: "이 영상은 이제 비활성 상태로 표시됩니다.",
                        preferredStyle: .alert
                    )
                    done.addAction(UIAlertAction(title: "확인", style: .default))
                    self.present(done, animated: true)
                    self.loadVideos()
                }
            } catch {
                progress?.dismiss(animated: true) { [weak self] in
                    guard let self else { return }
                    let failure = UIAlertController(
                        title: "비활성화 실패",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    failure.addAction(UIAlertAction(title: "확인", style: .default))
                    self.present(failure, animated: true)
                }
            }
        }
    }
}

// MARK: - AuthWebViewDelegate

extension VideoListViewController: AuthWebViewDelegate {
    func authDidComplete(tokenData: AuthTokenData) {
        switch WalletAccountValidator.validate(accountDid: tokenData.did) {
        case .matches:
            updateUI()
        case .noWallet, .accountDidMissing, .mismatch:
            JinBonAPIClient.shared.clearLocalSession()
            showSignupError("로그인 계정과 이 기기의 Wallet DID를 확인할 수 없거나 서로 다릅니다. 시작 화면에서 디지털 신원을 다시 연결해주세요.")
        }
    }

    func authDidCancel() {}

    func signupIdentityDidComplete(data: SignupIdentityData) {
        if WalletAPI.shared.isExistWallet() {
            let alert = UIAlertController(
                title: "기존 Wallet을 연결할까요?",
                message: "본인의 Wallet이 맞을 때만 새 진본 계정에 연결해주세요.",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            alert.addAction(UIAlertAction(title: "내 Wallet 연결", style: .default) { [weak self] _ in
                self?.completeSignupWithExistingWallet()
            })
            present(alert, animated: true)
        } else {
            showDidRegistration()
        }
    }

    private func completeSignupWithExistingWallet() {
        Task { @MainActor in
            guard let signupToken = Properties.getSignupToken(),
                  let didDoc = try? WalletAPI.shared.getDidDocument(type: .HolderDidDocumnet) else {
                showSignupError("기존 Wallet 정보를 확인할 수 없습니다.")
                return
            }
            do {
                _ = try await JinBonAPIClient.shared.completeSignup(signupToken: signupToken, did: didDoc.id)
                Properties.setRegDidDocCompleted(status: true)
                Properties.clearSignupToken()
                updateUI()
            } catch {
                showSignupError(error.localizedDescription)
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

    private func showSignupError(_ message: String) {
        let alert = UIAlertController(title: "회원가입 연결 실패", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - VideoTableViewCell

class VideoTableViewCell: UITableViewCell {

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let statusIcon = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .clear
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.cornerCurve = .continuous
        cardView.layer.masksToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
        ])

        let iconContainer = UIView()
        iconContainer.backgroundColor = ColorPalette.primary.withAlphaComponent(0.1)
        iconContainer.layer.cornerRadius = 22
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(iconContainer)

        statusIcon.image = UIImage(systemName: "film")
        statusIcon.tintColor = ColorPalette.primary
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(statusIcon)

        titleLabel.font = .jinBonFont(ofSize: 16, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)

        dateLabel.font = .jinBonFont(ofSize: 13)
        dateLabel.textColor = ColorPalette.secondaryText
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(dateLabel)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(chevron)

        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            iconContainer.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 44),
            iconContainer.heightAnchor.constraint(equalToConstant: 44),

            statusIcon.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            statusIcon.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            statusIcon.widthAnchor.constraint(equalToConstant: 38),
            statusIcon.heightAnchor.constraint(equalToConstant: 38),

            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            chevron.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    func configure(with video: VideoDetailData) {
        titleLabel.text = video.title
        let isActive = video.active != false
        if let thumbnail = JinBonVideoStore.thumbnail(videoId: video.videoId) {
            statusIcon.image = thumbnail
            statusIcon.contentMode = .scaleAspectFill
            statusIcon.clipsToBounds = true
            statusIcon.layer.cornerRadius = 8
            statusIcon.tintColor = nil
        } else {
            statusIcon.image = UIImage(systemName: isActive ? "film.fill" : "xmark.circle.fill")
            statusIcon.contentMode = .scaleAspectFit
            statusIcon.clipsToBounds = false
            statusIcon.layer.cornerRadius = 0
            statusIcon.tintColor = isActive ? ColorPalette.primary : ColorPalette.secondaryText
        }
        titleLabel.textColor = isActive ? ColorPalette.ink : ColorPalette.secondaryText
        if let dateStr = video.registeredAt {
            dateLabel.text = "\(String(dateStr.prefix(10))) · \(isActive ? "인증 유효" : "비활성")"
        } else {
            dateLabel.text = isActive ? "인증 유효" : "비활성"
        }
        isAccessibilityElement = true
        accessibilityLabel = "\(video.title), \(dateLabel.text ?? "")"
        accessibilityHint = "영상 상세 정보와 관리 메뉴를 엽니다"
        accessibilityTraits = .button
    }
}

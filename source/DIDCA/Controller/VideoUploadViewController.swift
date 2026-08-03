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
import PhotosUI
import AVFoundation

class VideoUploadViewController: UIViewController {

    var showsCloseButton = true

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let thumbnailView = UIImageView()
    private let fileNameLabel = UILabel()
    private let titleField = UITextField()
    private let titleContainer = UIView()
    private let uploadButton = UIButton(type: .system)
    private let resultView = UIView()
    private let resultTitleLabel = UILabel()
    private let resultMessageLabel = UILabel()
    private let vcStatusLabel = UILabel()
    private let resultDetailLabel = UILabel()

    private var selectedVideoURL: URL?
    private var isUploadComplete = false
    private var issuedVcId: String?
    private var resumedVcResult: VideoRegisterData?
    private weak var completionViewController: VideoRegistrationCompletionViewController?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorPalette.canvas
        title = "원본 영상 등록"

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ColorPalette.canvas
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: ColorPalette.ink]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = ColorPalette.primary

        if showsCloseButton {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "닫기", style: .plain, target: self, action: #selector(closeTapped))
        }

        setupUI()
        setupKeyboardHandling()
        if let resumedVcResult {
            DispatchQueue.main.async { [weak self] in
                self?.showResult(resumedVcResult)
                self?.offerVcIssuanceIfNeeded(resumedVcResult)
            }
        }
    }

    func resumeVcIssuance(with result: VideoRegisterData) {
        resumedVcResult = result
        guard isViewLoaded else { return }
        showResult(result)
        offerVcIssuanceIfNeeded(result)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        if let selectedVideoURL {
            try? FileManager.default.removeItem(at: selectedVideoURL)
        }
    }

    // MARK: - Setup

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -44)
        ])

        let eyebrow = UILabel()
        eyebrow.text = "원본 등록"
        eyebrow.font = .jinBonFont(ofSize: 12, weight: .bold)
        eyebrow.textColor = ColorPalette.primary

        let heading = UILabel()
        heading.numberOfLines = 0
        heading.font = .jinBonFont(ofSize: 28, weight: .bold)
        heading.textColor = ColorPalette.ink
        heading.setJinBonText("원본 영상을 등록하세요", lineSpacing: 7)

        let description = UILabel()
        description.numberOfLines = 0
        description.font = .jinBonFont(ofSize: 15, weight: .regular)
        description.textColor = ColorPalette.secondaryText
        description.setJinBonText("영상 해시를 블록체인에 기록해요.")

        [eyebrow, heading, description].forEach(contentStack.addArrangedSubview)
        contentStack.setCustomSpacing(6, after: eyebrow)
        contentStack.setCustomSpacing(10, after: heading)
        contentStack.setCustomSpacing(34, after: description)

        contentStack.addArrangedSubview(sectionHeader(step: "1", title: "원본 영상 선택", caption: "MP4, MOV 등 갤러리의 영상 파일"))

        // 영상 선택 영역
        let selectArea = UIView()
        selectArea.backgroundColor = ColorPalette.softBlue
        selectArea.layer.cornerRadius = 22
        selectArea.layer.cornerCurve = .continuous
        selectArea.layer.borderWidth = 1
        selectArea.layer.borderColor = ColorPalette.primary.withAlphaComponent(0.22).cgColor
        selectArea.clipsToBounds = true
        selectArea.translatesAutoresizingMaskIntoConstraints = false
        selectArea.isUserInteractionEnabled = true
        selectArea.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectVideoTapped)))

        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        thumbnailView.layer.cornerRadius = 22
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false

        let selectIcon = UIImageView(image: UIImage(systemName: "video.badge.plus"))
        selectIcon.tintColor = .white
        selectIcon.backgroundColor = ColorPalette.primary
        selectIcon.contentMode = .center
        selectIcon.layer.cornerRadius = 28
        selectIcon.translatesAutoresizingMaskIntoConstraints = false
        selectIcon.tag = 100

        let selectLabel = UILabel()
        selectLabel.text = "탭하여 영상 선택"
        selectLabel.font = .jinBonFont(ofSize: 16, weight: .bold)
        selectLabel.textColor = ColorPalette.ink
        selectLabel.tag = 101
        selectLabel.translatesAutoresizingMaskIntoConstraints = false

        fileNameLabel.font = .jinBonFont(ofSize: 12, weight: .semibold)
        fileNameLabel.textColor = .white
        fileNameLabel.backgroundColor = UIColor.black.withAlphaComponent(0.62)
        fileNameLabel.layer.cornerRadius = 13
        fileNameLabel.clipsToBounds = true
        fileNameLabel.textAlignment = .center
        fileNameLabel.isHidden = true
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false

        selectArea.addSubview(thumbnailView)
        selectArea.addSubview(selectIcon)
        selectArea.addSubview(selectLabel)
        selectArea.addSubview(fileNameLabel)

        NSLayoutConstraint.activate([
            selectArea.heightAnchor.constraint(equalToConstant: 210),

            thumbnailView.topAnchor.constraint(equalTo: selectArea.topAnchor),
            thumbnailView.leadingAnchor.constraint(equalTo: selectArea.leadingAnchor),
            thumbnailView.trailingAnchor.constraint(equalTo: selectArea.trailingAnchor),
            thumbnailView.bottomAnchor.constraint(equalTo: selectArea.bottomAnchor),

            selectIcon.centerXAnchor.constraint(equalTo: selectArea.centerXAnchor),
            selectIcon.centerYAnchor.constraint(equalTo: selectArea.centerYAnchor, constant: -18),
            selectIcon.widthAnchor.constraint(equalToConstant: 56),
            selectIcon.heightAnchor.constraint(equalToConstant: 56),

            selectLabel.centerXAnchor.constraint(equalTo: selectArea.centerXAnchor),
            selectLabel.topAnchor.constraint(equalTo: selectIcon.bottomAnchor, constant: 12),

            fileNameLabel.centerXAnchor.constraint(equalTo: selectArea.centerXAnchor),
            fileNameLabel.bottomAnchor.constraint(equalTo: selectArea.bottomAnchor, constant: -14),
            fileNameLabel.leadingAnchor.constraint(equalTo: selectArea.leadingAnchor, constant: 14),
            fileNameLabel.trailingAnchor.constraint(equalTo: selectArea.trailingAnchor, constant: -14),
            fileNameLabel.heightAnchor.constraint(equalToConstant: 34)
        ])

        contentStack.addArrangedSubview(selectArea)
        contentStack.setCustomSpacing(34, after: selectArea)

        contentStack.addArrangedSubview(sectionHeader(step: "2", title: "영상 정보", caption: "내 영상에서 쉽게 구분할 이름"))

        // 제목 입력
        titleContainer.backgroundColor = .white
        titleContainer.layer.cornerRadius = 18
        titleContainer.layer.cornerCurve = .continuous
        titleContainer.translatesAutoresizingMaskIntoConstraints = false

        let titleHeaderLabel = UILabel()
        titleHeaderLabel.text = "제목"
        titleHeaderLabel.font = .jinBonFont(ofSize: 13, weight: .bold)
        titleHeaderLabel.textColor = ColorPalette.secondaryText
        titleHeaderLabel.translatesAutoresizingMaskIntoConstraints = false

        titleField.attributedPlaceholder = NSAttributedString(
            string: "영상 제목을 입력하세요",
            attributes: [
                .foregroundColor: ColorPalette.secondaryText,
                .font: UIFont.jinBonFont(ofSize: 16, weight: .regular)
            ]
        )
        titleField.borderStyle = .none
        titleField.font = .jinBonFont(ofSize: 17, weight: .semibold)
        titleField.textColor = ColorPalette.ink
        titleField.clearButtonMode = .whileEditing
        titleField.returnKeyType = .done
        titleField.delegate = self
        titleField.translatesAutoresizingMaskIntoConstraints = false

        titleContainer.addSubview(titleHeaderLabel)
        titleContainer.addSubview(titleField)

        NSLayoutConstraint.activate([
            titleHeaderLabel.topAnchor.constraint(equalTo: titleContainer.topAnchor, constant: 16),
            titleHeaderLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor, constant: 18),
            titleHeaderLabel.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor, constant: -18),

            titleField.topAnchor.constraint(equalTo: titleHeaderLabel.bottomAnchor, constant: 4),
            titleField.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor, constant: 18),
            titleField.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor, constant: -18),
            titleField.heightAnchor.constraint(equalToConstant: 42),
            titleField.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: -10)
        ])

        contentStack.addArrangedSubview(titleContainer)
        contentStack.setCustomSpacing(26, after: titleContainer)

        let notice = infoCard()
        contentStack.addArrangedSubview(notice)
        contentStack.setCustomSpacing(30, after: notice)

        // 업로드 버튼
        uploadButton.setTitle("원본 영상 등록하기", for: .normal)
        uploadButton.setImage(UIImage(systemName: "checkmark.shield.fill"), for: .normal)
        uploadButton.tintColor = .white
        uploadButton.configuration = {
            var configuration = UIButton.Configuration.filled()
            configuration.baseBackgroundColor = ColorPalette.primary
            configuration.baseForegroundColor = .white
            configuration.cornerStyle = .large
            configuration.image = UIImage(systemName: "checkmark.shield.fill")
            configuration.imagePadding = 9
            configuration.title = "원본 영상 등록하기"
            configuration.attributedTitle?.font = .jinBonFont(ofSize: 16, weight: .bold)
            return configuration
        }()
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.addTarget(self, action: #selector(uploadTapped), for: .touchUpInside)
        uploadButton.heightAnchor.constraint(equalToConstant: 56).isActive = true

        contentStack.addArrangedSubview(uploadButton)

        // 결과 표시
        resultView.backgroundColor = .white
        resultView.layer.cornerRadius = 22
        resultView.layer.cornerCurve = .continuous
        resultView.layer.borderWidth = 1
        resultView.layer.borderColor = ColorPalette.success.withAlphaComponent(0.22).cgColor
        resultView.isHidden = true
        resultView.translatesAutoresizingMaskIntoConstraints = false

        let resultIcon = UIImageView(image: UIImage(systemName: "checkmark.shield.fill"))
        resultIcon.tintColor = ColorPalette.success
        resultIcon.contentMode = .scaleAspectFit
        resultIcon.widthAnchor.constraint(equalToConstant: 34).isActive = true
        resultIcon.heightAnchor.constraint(equalToConstant: 34).isActive = true

        resultTitleLabel.font = .jinBonFont(ofSize: 18, weight: .bold)
        resultTitleLabel.textColor = ColorPalette.ink
        resultMessageLabel.font = .jinBonFont(ofSize: 14, weight: .regular)
        resultMessageLabel.textColor = ColorPalette.secondaryText
        resultMessageLabel.numberOfLines = 0

        vcStatusLabel.font = .jinBonFont(ofSize: 13, weight: .bold)
        vcStatusLabel.textAlignment = .center
        vcStatusLabel.layer.cornerRadius = 14
        vcStatusLabel.clipsToBounds = true
        vcStatusLabel.heightAnchor.constraint(equalToConstant: 28).isActive = true

        resultDetailLabel.numberOfLines = 0
        resultDetailLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        resultDetailLabel.textColor = ColorPalette.secondaryText

        let headingLabels = UIStackView(arrangedSubviews: [resultTitleLabel, resultMessageLabel])
        headingLabels.axis = .vertical
        headingLabels.spacing = 5
        let headingRow = UIStackView(arrangedSubviews: [resultIcon, headingLabels])
        headingRow.axis = .horizontal
        headingRow.alignment = .top
        headingRow.spacing = 12

        let resultStack = UIStackView(arrangedSubviews: [headingRow, vcStatusLabel, resultDetailLabel])
        resultStack.axis = .vertical
        resultStack.spacing = 16
        resultStack.translatesAutoresizingMaskIntoConstraints = false
        resultView.addSubview(resultStack)

        NSLayoutConstraint.activate([
            resultStack.topAnchor.constraint(equalTo: resultView.topAnchor, constant: 20),
            resultStack.leadingAnchor.constraint(equalTo: resultView.leadingAnchor, constant: 20),
            resultStack.trailingAnchor.constraint(equalTo: resultView.trailingAnchor, constant: -20),
            resultStack.bottomAnchor.constraint(equalTo: resultView.bottomAnchor, constant: -20)
        ])

        contentStack.addArrangedSubview(resultView)
    }

    private func sectionHeader(step: String, title: String, caption: String) -> UIView {
        let badge = UILabel()
        badge.text = step
        badge.textAlignment = .center
        badge.font = .jinBonFont(ofSize: 13, weight: .bold)
        badge.textColor = .white
        badge.backgroundColor = ColorPalette.primary
        badge.layer.cornerRadius = 12
        badge.clipsToBounds = true
        badge.widthAnchor.constraint(equalToConstant: 24).isActive = true
        badge.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .jinBonFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = ColorPalette.ink
        let captionLabel = UILabel()
        captionLabel.text = caption
        captionLabel.font = .jinBonFont(ofSize: 13, weight: .medium)
        captionLabel.textColor = ColorPalette.secondaryText
        let labels = UIStackView(arrangedSubviews: [titleLabel, captionLabel])
        labels.axis = .vertical
        labels.spacing = 5
        let row = UIStackView(arrangedSubviews: [badge, labels])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        return row
    }

    private func infoCard() -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "lock.shield.fill"))
        icon.tintColor = ColorPalette.primary
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 22).isActive = true

        let label = UILabel()
        label.numberOfLines = 0
        label.font = .jinBonFont(ofSize: 13, weight: .medium)
        label.textColor = ColorPalette.secondaryText
        label.setJinBonText("원본은 서버에 저장되지 않고 해시만 등록돼요.", lineSpacing: 4)

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        row.backgroundColor = ColorPalette.softBlue
        row.layer.cornerRadius = 16
        return row
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func selectVideoTapped() {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func uploadTapped() {
        view.endEditing(true)

        if isUploadComplete {
            dismiss(animated: true)
            return
        }

        guard Properties.isLoggedIn() else {
            showAlert("영상 등록은 로그인이 필요합니다. 내 진본 탭에서 로그인해주세요.")
            return
        }
        guard Properties.getMemberRole() == "ISSUER" else {
            showAlert("공인 등록 권한이 있는 계정만 영상을 등록할 수 있습니다.")
            return
        }
        guard let videoURL = selectedVideoURL else {
            showAlert("영상을 선택해주세요")
            return
        }
        guard let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
            showAlert("제목을 입력해주세요")
            return
        }

        uploadButton.isEnabled = false
        var progressConfiguration = uploadButton.configuration
        progressConfiguration?.title = "블록체인에 등록 중..."
        progressConfiguration?.image = nil
        progressConfiguration?.showsActivityIndicator = true
        uploadButton.configuration = progressConfiguration

        Task {
            do {
                let result = try await JinBonAPIClient.shared.uploadVideo(fileURL: videoURL, title: title)
                DispatchQueue.main.async { [weak self] in
                    self?.showResult(result)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.showAlert("업로드 실패: \(error.localizedDescription)")
                    self?.uploadButton.isEnabled = true
                    var configuration = self?.uploadButton.configuration
                    configuration?.title = "원본 영상 등록하기"
                    configuration?.image = UIImage(systemName: "checkmark.shield.fill")
                    configuration?.showsActivityIndicator = false
                    self?.uploadButton.configuration = configuration
                }
            }
        }
    }

    private func showResult(_ data: VideoRegisterData) {
        if let videoId = data.videoId, let selectedVideoURL {
            try? JinBonVideoStore.save(sourceURL: selectedVideoURL, videoId: videoId)
            removeTemporaryVideoIfNeeded(selectedVideoURL)
            self.selectedVideoURL = nil
        }
        isUploadComplete = true
        let completion = VideoRegistrationCompletionViewController(data: data)
        completion.onClose = { [weak self] in self?.dismiss(animated: true) }
        completion.onIssue = { [weak self] in self?.offerVcIssuanceIfNeeded(data) }
        completionViewController = completion
        navigationController?.pushViewController(completion, animated: true)
    }

    private func offerVcIssuanceIfNeeded(_ data: VideoRegisterData) {
        guard data.vcId == nil, let videoId = data.videoId else { return }

        if let pending = Properties.getPendingVideoVc(videoId: videoId) {
            reconnectIssuedVc(videoId: videoId, pending: pending)
            return
        }

        guard
              let vcPlanId = data.vcPlanId,
              let issuerDid = data.vcIssuerDid,
              let offerId = data.vcOfferId else { return }

        let alert = JinBonVcOfferViewController()
        alert.onIssue = { [weak self] in
            self?.prepareVcIssuance(videoId: videoId, vcPlanId: vcPlanId,
                                    issuerDid: issuerDid, offerId: offerId)
        }
        alert.modalPresentationStyle = .overFullScreen
        alert.modalTransitionStyle = .crossDissolve
        (navigationController?.topViewController ?? self).present(alert, animated: true)
    }

    private func prepareVcIssuance(videoId: Int, vcPlanId: String, issuerDid: String, offerId: String) {
        let presenter = navigationController?.topViewController ?? self
        ActivityUtil.show(vc: presenter) {
            try await IssueVcProtocol.shared.preProcess(
                vcPlanId: vcPlanId, issuer: issuerDid, offerId: offerId)
        } completeClosure: { [weak self] in
            guard let self else { return }
            SelectAuthHelper.showPreferredBiometric(on: presenter) { [weak self] passcode in
                self?.issueVc(videoId: videoId, offerId: offerId, passcode: passcode)
            } cancelClosure: { [weak self] in
                IssueVcProtocol.shared.cancelIssuance()
                self?.showAlert("디지털 증명서 발급이 취소됐어요. 발급 버튼에서 다시 시도할 수 있어요.")
            }
        } failureCloseClosure: { [weak self] title, message in
            guard let self else { return }
            PopupUtils.showAlertPopup(title: title, content: message, VC: self)
        }
    }

    private func issueVc(videoId: Int, offerId: String, passcode: String?) {
        let presenter = navigationController?.topViewController ?? self
        ActivityUtil.show(vc: presenter) {
            let vcId = try await IssueVcProtocol.shared.process(passcode: passcode)
            self.issuedVcId = vcId
            Properties.setPendingVideoVc(
                PendingVideoVcData(vcId: vcId, offerId: offerId),
                videoId: videoId
            )
            try await JinBonAPIClient.shared.completeVideoVc(
                videoId: videoId, vcId: vcId, offerId: offerId)
            Properties.clearPendingVideoVc(videoId: videoId)
        } completeClosure: { [weak self] in
            guard let self else { return }
            self.updateVcStatus(vcId: self.issuedVcId)
            self.completionViewController?.markVcIssued(vcId: self.issuedVcId)
            self.resultMessageLabel.setJinBonText(
                "영상 증적과 디지털 증명서가 모두 준비됐어요.", lineSpacing: 4)
            self.showAlert("디지털 증명서가 기기 Wallet에 안전하게 저장됐어요.")
        } failureCloseClosure: { [weak self] title, message in
            guard let self else { return }
            PopupUtils.showAlertPopup(title: title, content: message, VC: self)
        }
    }

    private func reconnectIssuedVc(videoId: Int, pending: PendingVideoVcData) {
        let presenter = navigationController?.topViewController ?? self
        ActivityUtil.show(vc: presenter) {
            try await JinBonAPIClient.shared.completeVideoVc(
                videoId: videoId, vcId: pending.vcId, offerId: pending.offerId)
            Properties.clearPendingVideoVc(videoId: videoId)
            self.issuedVcId = pending.vcId
        } completeClosure: { [weak self] in
            guard let self else { return }
            self.updateVcStatus(vcId: pending.vcId)
            self.completionViewController?.markVcIssued(vcId: pending.vcId)
            self.resultMessageLabel.setJinBonText(
                "기존 디지털 증명서를 영상에 다시 연결했어요.", lineSpacing: 4)
            self.showAlert("기기 Wallet에 저장된 디지털 증명서를 안전하게 다시 연결했어요.")
        } failureCloseClosure: { [weak self] title, message in
            guard let self else { return }
            PopupUtils.showAlertPopup(
                title: title,
                content: "디지털 증명서는 기기 Wallet에 보존되어 있습니다. 네트워크 연결 후 다시 시도해주세요.\n\n\(message)",
                VC: self
            )
        }
    }

    private func setupKeyboardHandling() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tap)
        scrollView.keyboardDismissMode = .interactive

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(dismissKeyboard))
        ]
        titleField.inputAccessoryView = toolbar

        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardFrame = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboardFrame.minY - view.safeAreaInsets.bottom)
        scrollView.contentInset.bottom = overlap
        scrollView.verticalScrollIndicatorInsets.bottom = overlap
        if titleField.isFirstResponder {
            scrollToTitleInput()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func scrollToTitleInput() {
        view.layoutIfNeeded()
        let rect = titleContainer.convert(titleContainer.bounds, to: scrollView)
        let maximumY = max(0, scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom)
        let targetY = min(maximumY, max(0, rect.minY - 24))
        scrollView.setContentOffset(CGPoint(x: 0, y: targetY), animated: true)
    }

    private func updateVcStatus(vcId: String?) {
        if let vcId, !vcId.isEmpty {
            vcStatusLabel.text = "  디지털 증명서 발급 완료  "
            vcStatusLabel.textColor = ColorPalette.success
            vcStatusLabel.backgroundColor = ColorPalette.success.withAlphaComponent(0.10)
            resultDetailLabel.text = (resultDetailLabel.text ?? "") + "\nVC ID     \(vcId)"
        } else {
            vcStatusLabel.text = "  디지털 증명서 발급 대기  "
            vcStatusLabel.textColor = ColorPalette.primary
            vcStatusLabel.backgroundColor = ColorPalette.softBlue
        }
    }
}

private final class VideoRegistrationCompletionViewController: UIViewController {

    var onClose: (() -> Void)?
    var onIssue: (() -> Void)?

    private let data: VideoRegisterData
    private let statusIcon = UIImageView()
    private let statusLabel = UILabel()
    private let issueButton = UIButton(type: .system)

    init(data: VideoRegisterData) {
        self.data = data
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorPalette.canvas
        title = "등록 완료"
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "닫기", style: .done, target: self, action: #selector(closeTapped)
        )

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false

        let iconBackground = UIView()
        iconBackground.backgroundColor = ColorPalette.success.withAlphaComponent(0.12)
        iconBackground.layer.cornerRadius = 38
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView(image: UIImage(systemName: "checkmark.shield.fill"))
        icon.tintColor = ColorPalette.success
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(icon)

        let heading = UILabel()
        heading.text = data.alreadyRegistered == true ? "기존 등록을 확인했어요" : "블록체인 등록 완료"
        heading.font = .jinBonFont(ofSize: 26, weight: .bold)
        heading.textColor = ColorPalette.ink
        heading.textAlignment = .center
        heading.numberOfLines = 0

        let message = UILabel()
        message.font = .jinBonFont(ofSize: 15, weight: .regular)
        message.textColor = ColorPalette.secondaryText
        message.textAlignment = .center
        message.numberOfLines = 0
        message.setJinBonText("영상 원본의 증적이 안전하게 기록됐어요.", lineSpacing: 5)

        let registeredDate = data.registeredAt.map { String($0.prefix(10)) } ?? "방금"
        let details = UIStackView(arrangedSubviews: [
            detailRow(title: "영상", value: data.title ?? "제목 없음"),
            detailRow(title: "등록일", value: registeredDate)
        ])
        details.axis = .vertical
        details.spacing = 16
        details.isLayoutMarginsRelativeArrangement = true
        details.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        details.backgroundColor = .white
        details.layer.cornerRadius = 20

        let certificateTitle = UILabel()
        certificateTitle.text = "디지털 증명서"
        certificateTitle.font = .jinBonFont(ofSize: 15, weight: .bold)
        certificateTitle.textColor = ColorPalette.ink

        statusIcon.contentMode = .scaleAspectFit
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        statusIcon.widthAnchor.constraint(equalToConstant: 20).isActive = true
        statusIcon.heightAnchor.constraint(equalToConstant: 20).isActive = true

        statusLabel.font = .jinBonFont(ofSize: 14, weight: .regular)
        statusLabel.textColor = ColorPalette.secondaryText
        statusLabel.numberOfLines = 0

        let statusRow = UIStackView(arrangedSubviews: [statusIcon, statusLabel])
        statusRow.axis = .horizontal
        statusRow.alignment = .top
        statusRow.spacing = 10

        let certificateSection = UIStackView(arrangedSubviews: [certificateTitle, statusRow])
        certificateSection.axis = .vertical
        certificateSection.spacing = 10
        certificateSection.isLayoutMarginsRelativeArrangement = true
        certificateSection.layoutMargins = UIEdgeInsets(top: 18, left: 20, bottom: 18, right: 20)
        certificateSection.backgroundColor = .white
        certificateSection.layer.cornerRadius = 20

        configureButton(issueButton, title: "디지털 증명서 발급하기", filled: true)
        issueButton.addTarget(self, action: #selector(issueTapped), for: .touchUpInside)
        issueButton.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let closeButton = UIButton(type: .system)
        configureButton(closeButton, title: "내 영상으로 돌아가기", filled: false)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.heightAnchor.constraint(equalToConstant: 54).isActive = true

        [iconBackground, heading, message, details, certificateSection, issueButton, closeButton].forEach(stack.addArrangedSubview)
        stack.alignment = .fill
        stack.setCustomSpacing(24, after: message)
        stack.setCustomSpacing(22, after: certificateSection)

        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 30),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -36),
            iconBackground.widthAnchor.constraint(equalToConstant: 76),
            iconBackground.heightAnchor.constraint(equalToConstant: 76),
            iconBackground.centerXAnchor.constraint(equalTo: stack.centerXAnchor),
            icon.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 38),
            icon.heightAnchor.constraint(equalToConstant: 38)
        ])
        markVcIssued(vcId: data.vcId)
    }

    func markVcIssued(vcId: String?) {
        let isIssued = !(vcId ?? "").isEmpty
        statusIcon.image = UIImage(systemName: isIssued ? "checkmark.circle.fill" : "circle.dashed")
        statusIcon.tintColor = isIssued ? ColorPalette.success : ColorPalette.secondaryText
        statusLabel.text = isIssued
            ? "발급이 완료되어 이 기기의 Wallet에 보관 중입니다."
            : "아직 발급하지 않았습니다. 원하면 아래에서 발급할 수 있습니다."
        statusLabel.textColor = isIssued ? ColorPalette.ink : ColorPalette.secondaryText
        issueButton.isHidden = isIssued
    }

    private func detailRow(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .jinBonFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = ColorPalette.secondaryText
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .jinBonFont(ofSize: 15, weight: .semibold)
        valueLabel.textColor = ColorPalette.ink
        valueLabel.numberOfLines = 0
        valueLabel.lineBreakMode = .byWordWrapping
        let row = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        row.axis = .vertical
        row.spacing = 6
        return row
    }

    private func configureButton(_ button: UIButton, title: String, filled: Bool) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .jinBonFont(ofSize: 16, weight: .bold)
        button.layer.cornerRadius = 16
        button.backgroundColor = filled ? ColorPalette.primary : .white
        button.setTitleColor(filled ? .white : ColorPalette.primary, for: .normal)
    }

    @objc private func issueTapped() { onIssue?() }
    @objc private func closeTapped() { onClose?() }
}

private final class JinBonVcOfferViewController: UIViewController {

    var onIssue: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.42)

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 28
        card.layer.cornerCurve = .continuous
        card.translatesAutoresizingMaskIntoConstraints = false

        let iconBackground = UIView()
        iconBackground.backgroundColor = ColorPalette.softBlue
        iconBackground.layer.cornerRadius = 28
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
        icon.tintColor = ColorPalette.primary
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(icon)

        let brand = UILabel()
        brand.text = "JINBON WALLET"
        brand.font = .jinBonFont(ofSize: 12, weight: .bold)
        brand.textColor = ColorPalette.primary
        brand.textAlignment = .center

        let title = UILabel()
        title.text = "디지털 증명서를 발급할까요?"
        title.font = .jinBonFont(ofSize: 22, weight: .bold)
        title.textColor = ColorPalette.ink
        title.textAlignment = .center
        title.numberOfLines = 0

        let message = UILabel()
        message.font = .jinBonFont(ofSize: 14, weight: .regular)
        message.textColor = ColorPalette.secondaryText
        message.textAlignment = .center
        message.numberOfLines = 0
        message.setJinBonText(
            "영상 등록 사실을 증명하는 디지털 증명서를 이 기기의 Wallet에 안전하게 저장합니다.",
            lineSpacing: 5
        )

        let laterButton = makeButton(title: "나중에", filled: false)
        laterButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        let issueButton = makeButton(title: "디지털 증명서 발급하기", filled: true)
        issueButton.addTarget(self, action: #selector(issue), for: .touchUpInside)

        let buttons = UIStackView(arrangedSubviews: [laterButton, issueButton])
        buttons.axis = .vertical
        buttons.spacing = 10

        let stack = UIStackView(arrangedSubviews: [iconBackground, brand, title, message, buttons])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        stack.setCustomSpacing(20, after: iconBackground)
        stack.setCustomSpacing(22, after: message)
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(card)
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
            iconBackground.widthAnchor.constraint(equalToConstant: 56),
            iconBackground.heightAnchor.constraint(equalToConstant: 56),
            iconBackground.centerXAnchor.constraint(equalTo: stack.centerXAnchor),
            icon.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28),
            brand.widthAnchor.constraint(equalTo: stack.widthAnchor),
            title.widthAnchor.constraint(equalTo: stack.widthAnchor),
            message.widthAnchor.constraint(equalTo: stack.widthAnchor),
            buttons.widthAnchor.constraint(equalTo: stack.widthAnchor),
            laterButton.heightAnchor.constraint(equalToConstant: 52),
            issueButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }

    private func makeButton(title: String, filled: Bool) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .jinBonFont(ofSize: 16, weight: .bold)
        button.layer.cornerRadius = 16
        if filled {
            button.backgroundColor = ColorPalette.primary
            button.setTitleColor(.white, for: .normal)
        } else {
            button.backgroundColor = ColorPalette.canvas
            button.setTitleColor(ColorPalette.secondaryText, for: .normal)
        }
        return button
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    @objc private func issue() {
        let action = onIssue
        dismiss(animated: true) { action?() }
    }
}

extension VideoUploadViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        DispatchQueue.main.async { [weak self] in self?.scrollToTitleInput() }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - PHPickerViewControllerDelegate

extension VideoUploadViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }

        let provider = result.itemProvider

        if provider.hasItemConformingToTypeIdentifier("public.movie") {
            provider.loadFileRepresentation(forTypeIdentifier: "public.movie") { [weak self] url, error in
                guard let url = url else { return }

                // 복사본 생성 (임시 디렉토리)
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(url.pathExtension)
                do {
                    try FileManager.default.copyItem(at: url, to: tempURL)
                } catch {
                    DispatchQueue.main.async {
                        self?.showAlert("선택한 영상을 준비하지 못했습니다: \(error.localizedDescription)")
                    }
                    return
                }

                DispatchQueue.main.async {
                    if let previous = self?.selectedVideoURL {
                        self?.removeTemporaryVideoIfNeeded(previous)
                    }
                    self?.selectedVideoURL = tempURL
                    self?.fileNameLabel.text = url.lastPathComponent
                    self?.fileNameLabel.isHidden = false

                    self?.generateThumbnail(from: tempURL)
                }
            }
        }
    }

    private func generateThumbnail(from url: URL) {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        let time = CMTimeMake(value: 1, timescale: 2)
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] _, image, _, _, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self?.thumbnailView.image = UIImage(cgImage: image)
                    // 선택 아이콘/라벨 숨기기
                    if let selectArea = self?.thumbnailView.superview {
                        selectArea.viewWithTag(100)?.isHidden = true
                        selectArea.viewWithTag(101)?.isHidden = true
                    }
                }
            }
        }
    }

    private func removeTemporaryVideoIfNeeded(_ url: URL) {
        let temporaryPath = FileManager.default.temporaryDirectory.standardizedFileURL.path
        let candidatePath = url.standardizedFileURL.path
        guard candidatePath.hasPrefix(temporaryPath) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

enum JinBonVideoStore {
    private static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("JinBonVideos", isDirectory: true)
    }

    static func save(sourceURL: URL, videoId: Int) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        remove(videoId: videoId)

        let ext = sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension.lowercased()
        let destination = directory.appendingPathComponent("video-\(videoId).\(ext)")
        try FileManager.default.copyItem(at: sourceURL, to: destination)

        let asset = AVAsset(url: destination)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        if let image = try? generator.copyCGImage(at: CMTime(seconds: 0.5, preferredTimescale: 600), actualTime: nil),
           let data = UIImage(cgImage: image).jpegData(compressionQuality: 0.78) {
            try? data.write(to: thumbnailURL(videoId: videoId), options: .atomic)
        }
    }

    static func videoURL(videoId: Int) -> URL? {
        let prefix = "video-\(videoId)."
        return try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        ).first { $0.lastPathComponent.hasPrefix(prefix) }
    }

    static func thumbnail(videoId: Int) -> UIImage? {
        UIImage(contentsOfFile: thumbnailURL(videoId: videoId).path)
    }

    static func remove(videoId: Int) {
        if let url = videoURL(videoId: videoId) {
            try? FileManager.default.removeItem(at: url)
        }
        try? FileManager.default.removeItem(at: thumbnailURL(videoId: videoId))
    }

    private static func thumbnailURL(videoId: Int) -> URL {
        directory.appendingPathComponent("thumbnail-\(videoId).jpg")
    }
}

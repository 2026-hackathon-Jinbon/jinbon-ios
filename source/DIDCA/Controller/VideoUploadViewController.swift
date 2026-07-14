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

class VideoUploadViewController: UIViewController {

    var showsCloseButton = true

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let thumbnailView = UIImageView()
    private let fileNameLabel = UILabel()
    private let titleField = UITextField()
    private let uploadButton = UIButton(type: .system)
    private let resultView = UIView()
    private let resultLabel = UILabel()

    private var selectedVideoURL: URL?
    private var isUploadComplete = false

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
        contentStack.spacing = 16
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

        let eyebrow = UILabel()
        eyebrow.text = "BLOCKCHAIN ORIGINAL"
        eyebrow.font = .systemFont(ofSize: 12, weight: .bold)
        eyebrow.textColor = ColorPalette.primary

        let heading = UILabel()
        heading.text = "영상의 원본을\n블록체인에 증명하세요"
        heading.numberOfLines = 0
        heading.font = .systemFont(ofSize: 28, weight: .bold)
        heading.textColor = ColorPalette.ink

        let description = UILabel()
        description.text = "등록 후 생성된 해시와 인증 기록으로 영상의 진본 여부를 확인할 수 있어요."
        description.numberOfLines = 0
        description.font = .systemFont(ofSize: 15, weight: .regular)
        description.textColor = ColorPalette.secondaryText

        [eyebrow, heading, description].forEach(contentStack.addArrangedSubview)
        contentStack.setCustomSpacing(6, after: eyebrow)
        contentStack.setCustomSpacing(10, after: heading)
        contentStack.setCustomSpacing(24, after: description)

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
        selectLabel.font = .systemFont(ofSize: 16, weight: .bold)
        selectLabel.textColor = ColorPalette.ink
        selectLabel.tag = 101
        selectLabel.translatesAutoresizingMaskIntoConstraints = false

        fileNameLabel.font = .systemFont(ofSize: 12, weight: .semibold)
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
        contentStack.setCustomSpacing(24, after: selectArea)

        contentStack.addArrangedSubview(sectionHeader(step: "2", title: "영상 정보", caption: "내 영상에서 쉽게 구분할 이름"))

        // 제목 입력
        let titleContainer = UIView()
        titleContainer.backgroundColor = .white
        titleContainer.layer.cornerRadius = 18
        titleContainer.layer.cornerCurve = .continuous
        titleContainer.translatesAutoresizingMaskIntoConstraints = false

        let titleHeaderLabel = UILabel()
        titleHeaderLabel.text = "제목"
        titleHeaderLabel.font = .systemFont(ofSize: 13, weight: .bold)
        titleHeaderLabel.textColor = ColorPalette.secondaryText
        titleHeaderLabel.translatesAutoresizingMaskIntoConstraints = false

        titleField.placeholder = "영상 제목을 입력하세요"
        titleField.borderStyle = .none
        titleField.font = .systemFont(ofSize: 17, weight: .semibold)
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
        contentStack.setCustomSpacing(20, after: titleContainer)

        let notice = infoCard()
        contentStack.addArrangedSubview(notice)
        contentStack.setCustomSpacing(20, after: notice)

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
            configuration.attributedTitle?.font = .systemFont(ofSize: 16, weight: .bold)
            return configuration
        }()
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.addTarget(self, action: #selector(uploadTapped), for: .touchUpInside)
        uploadButton.heightAnchor.constraint(equalToConstant: 56).isActive = true

        contentStack.addArrangedSubview(uploadButton)

        // 결과 표시
        resultView.backgroundColor = ColorPalette.success.withAlphaComponent(0.09)
        resultView.layer.cornerRadius = 18
        resultView.isHidden = true
        resultView.translatesAutoresizingMaskIntoConstraints = false

        resultLabel.numberOfLines = 0
        resultLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        resultLabel.textColor = ColorPalette.ink
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultView.addSubview(resultLabel)

        NSLayoutConstraint.activate([
            resultLabel.topAnchor.constraint(equalTo: resultView.topAnchor, constant: 16),
            resultLabel.leadingAnchor.constraint(equalTo: resultView.leadingAnchor, constant: 16),
            resultLabel.trailingAnchor.constraint(equalTo: resultView.trailingAnchor, constant: -16),
            resultLabel.bottomAnchor.constraint(equalTo: resultView.bottomAnchor, constant: -16)
        ])

        contentStack.addArrangedSubview(resultView)
    }

    private func sectionHeader(step: String, title: String, caption: String) -> UIView {
        let badge = UILabel()
        badge.text = step
        badge.textAlignment = .center
        badge.font = .systemFont(ofSize: 13, weight: .bold)
        badge.textColor = .white
        badge.backgroundColor = ColorPalette.primary
        badge.layer.cornerRadius = 12
        badge.clipsToBounds = true
        badge.widthAnchor.constraint(equalToConstant: 24).isActive = true
        badge.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = ColorPalette.ink
        let captionLabel = UILabel()
        captionLabel.text = caption
        captionLabel.font = .systemFont(ofSize: 13, weight: .medium)
        captionLabel.textColor = ColorPalette.secondaryText
        let labels = UIStackView(arrangedSubviews: [titleLabel, captionLabel])
        labels.axis = .vertical
        labels.spacing = 2
        let row = UIStackView(arrangedSubviews: [badge, labels])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        return row
    }

    private func infoCard() -> UIView {
        let icon = UIImageView(image: UIImage(systemName: "lock.shield.fill"))
        icon.tintColor = ColorPalette.primary
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 22).isActive = true

        let label = UILabel()
        label.text = "원본 파일은 서버에 저장되지 않아요\n영상의 해시와 인증 기록만 안전하게 등록됩니다."
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = ColorPalette.secondaryText

        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 15, left: 16, bottom: 15, right: 16)
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
        progressConfiguration?.image = UIImage(systemName: "arrow.triangle.2.circlepath")
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
                    self?.uploadButton.configuration = configuration
                }
            }
        }
    }

    private func showResult(_ data: VideoRegisterData) {
        if let videoId = data.videoId, let selectedVideoURL {
            try? JinBonVideoStore.save(sourceURL: selectedVideoURL, videoId: videoId)
        }
        isUploadComplete = true
        uploadButton.isEnabled = true
        var configuration = uploadButton.configuration
        configuration?.title = "등록 완료"
        configuration?.image = UIImage(systemName: "checkmark.circle.fill")
        configuration?.baseBackgroundColor = ColorPalette.success
        uploadButton.configuration = configuration

        resultView.isHidden = false
        resultLabel.text = """
        등록 완료!

        Tx Hash: \(data.txHash ?? "-")
        Block: \(data.blockNumber ?? "-")
        VC ID: \(data.vcId ?? "-")
        Merkle Root: \(data.merkleRoot ?? "-")
        """

        scrollView.setContentOffset(
            CGPoint(x: 0, y: max(0, scrollView.contentSize.height - scrollView.bounds.height)),
            animated: true
        )
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
            scrollView.scrollRectToVisible(titleField.convert(titleField.bounds, to: scrollView), animated: true)
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
}

extension VideoUploadViewController: UITextFieldDelegate {
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
                try? FileManager.default.copyItem(at: url, to: tempURL)

                DispatchQueue.main.async {
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
}

import AVFoundation

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

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

class VideoVerifyViewController: UIViewController {

    var showsCloseButton = true

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let thumbnailView = UIImageView()
    private let fileNameLabel = UILabel()
    private let verifyButton = UIButton(type: .system)
    private let resultCard = UIView()

    private var selectedVideoURL: URL?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorPalette.canvas
        title = "영상 검증"

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
    }

    deinit {
        if let selectedVideoURL {
            try? FileManager.default.removeItem(at: selectedVideoURL)
        }
    }

    // MARK: - Setup

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
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

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32)
        ])

        // 안내 문구
        let infoLabel = UILabel()
        let infoText = "공식 등록 영상과 비교하세요\n갤러리에서 영상 하나를 선택하면 돼요."
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 7
        let attributedInfo = NSMutableAttributedString(
            string: infoText,
            attributes: [
                .font: UIFont.jinBonFont(ofSize: 15),
                .foregroundColor: ColorPalette.secondaryText,
                .paragraphStyle: paragraph
            ]
        )
        attributedInfo.addAttributes([
            .font: UIFont.jinBonFont(ofSize: 19, weight: .bold),
            .foregroundColor: ColorPalette.ink
        ], range: NSRange(location: 0, length: "공식 등록 영상과 비교하세요".utf16.count))
        infoLabel.attributedText = attributedInfo
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        contentStack.addArrangedSubview(infoLabel)

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
        selectArea.isAccessibilityElement = true
        selectArea.accessibilityLabel = "검증할 영상 선택"
        selectArea.accessibilityHint = "사진 보관함에서 영상 한 개를 선택합니다"
        selectArea.accessibilityTraits = .button

        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        thumbnailView.layer.cornerRadius = 22
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false

        let selectIcon = UIImageView(image: UIImage(systemName: "video.badge.checkmark"))
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
            selectIcon.centerYAnchor.constraint(equalTo: selectArea.centerYAnchor, constant: -16),
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

        // 검증 버튼
        verifyButton.setTitle("영상 검증하기", for: .normal)
        verifyButton.titleLabel?.font = .jinBonFont(ofSize: 16, weight: .bold)
        verifyButton.backgroundColor = ColorPalette.primary
        verifyButton.setTitleColor(.white, for: .normal)
        verifyButton.layer.cornerRadius = 16
        verifyButton.translatesAutoresizingMaskIntoConstraints = false
        verifyButton.addTarget(self, action: #selector(verifyTapped), for: .touchUpInside)
        verifyButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        verifyButton.accessibilityHint = "선택한 영상의 등록 기록과 보증서를 확인합니다"
        setVerifyButton(enabled: false, title: "영상을 먼저 선택해주세요")

        contentStack.addArrangedSubview(verifyButton)

        // 결과 카드
        resultCard.layer.cornerRadius = 18
        resultCard.isHidden = true
        resultCard.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(resultCard)
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

    @objc private func verifyTapped() {
        guard let videoURL = selectedVideoURL else {
            showAlert("검증할 영상을 선택해주세요")
            return
        }

        setVerifyButton(enabled: false, title: "검증 중...")

        Task {
            do {
                let result = try await JinBonAPIClient.shared.verifyVideo(fileURL: videoURL)
                DispatchQueue.main.async { [weak self] in
                    self?.showResult(result)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.showAlert("검증 실패: \(error.localizedDescription)")
                    self?.setVerifyButton(enabled: true, title: "영상 검증하기")
                }
            }
        }
    }

    private func showResult(_ data: VideoVerifyData) {
        setVerifyButton(enabled: true, title: "다시 검증")

        resultCard.isHidden = false
        resultCard.subviews.forEach { $0.removeFromSuperview() }

        let presentation = resultPresentation(for: data.effectiveVerdict)
        resultCard.backgroundColor = ColorPalette.card
        resultCard.layer.borderWidth = 1
        resultCard.layer.borderColor = presentation.color.withAlphaComponent(0.28).cgColor
        resultCard.layer.shadowColor = ColorPalette.elevatedShadow.cgColor
        resultCard.layer.shadowOpacity = 0.08
        resultCard.layer.shadowRadius = 14
        resultCard.layer.shadowOffset = CGSize(width: 0, height: 6)
        resultCard.isAccessibilityElement = true
        resultCard.accessibilityLabel = "검증 결과, \(presentation.title)"

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        // 결과 아이콘 + 텍스트
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center

        let icon = UIImageView(image: UIImage(systemName: presentation.symbol))
        icon.tintColor = presentation.color
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 28).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 28).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = presentation.title
        titleLabel.font = .jinBonFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = ColorPalette.ink
        titleLabel.numberOfLines = 0

        headerStack.addArrangedSubview(icon)
        headerStack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(headerStack)

        // 상세 정보
        let details: [(String, String)] = [
            ("영상 디지털 지문", contentMatchText(for: data.effectiveVerdict)),
            ("블록체인 등록", data.blockchainVerified ? "확인됨" : "확인되지 않음"),
            ("진본 VC 보증서", certificateText(for: data))
        ]

        for (label, value) in details {
            let row = makeDetailRow(label: label, value: value)
            stack.addArrangedSubview(row)
        }

        if let message = data.message, !message.isEmpty {
            stack.addArrangedSubview(makeCallout(
                text: message,
                textColor: ColorPalette.ink,
                backgroundColor: presentation.color.withAlphaComponent(0.08),
                font: .jinBonFont(ofSize: 15, weight: .semibold)
            ))
        }

        if let registeredAt = data.registeredAt {
            let row = makeDetailRow(label: "등록일", value: String(registeredAt.prefix(10)))
            stack.addArrangedSubview(row)
        }

        if let distance = data.similarityDistance,
           data.effectiveVerdict == .similarMatch {
            stack.addArrangedSubview(makeDetailRow(
                label: "유사도 거리", value: String(format: "%.1f", distance)))
        }

        if let notice = data.notice, !notice.isEmpty {
            stack.addArrangedSubview(makeCallout(
                text: notice,
                textColor: ColorPalette.secondaryText,
                backgroundColor: ColorPalette.canvas,
                font: .jinBonFont(ofSize: 13, weight: .medium)
            ))
        }

        resultCard.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: resultCard.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: resultCard.bottomAnchor, constant: -20)
        ])
        UIAccessibility.post(notification: .announcement, argument: presentation.title)
    }

    private func setVerifyButton(enabled: Bool, title: String) {
        verifyButton.isEnabled = enabled
        verifyButton.alpha = enabled ? 1 : 0.55
        verifyButton.setTitle(title, for: .normal)
    }

    private func resultPresentation(
        for verdict: VideoVerificationVerdict
    ) -> (title: String, symbol: String, color: UIColor) {
        switch verdict {
        case .exactMatch:
            return ("등록 영상과 정확히 일치합니다", "checkmark.seal.fill", .systemGreen)
        case .sameContent:
            return ("등록된 영상과 내용이 일치합니다", "checkmark.circle.fill", ColorPalette.primary)
        case .similarMatch:
            return ("등록 영상과 유사합니다", "equal.circle.fill", .systemBlue)
        case .registeredButRevoked:
            return ("비활성화된 등록 영상입니다", "exclamationmark.shield.fill", .systemOrange)
        case .certificateInvalid:
            return ("등록은 확인됐지만 보증서가 유효하지 않습니다", "xmark.shield.fill", .systemOrange)
        case .notRegistered:
            return ("등록 기록을 찾지 못했습니다", "questionmark.circle.fill", .systemGray)
        case .verificationUnavailable:
            return ("현재 검증할 수 없습니다", "exclamationmark.triangle.fill", .systemOrange)
        }
    }

    private func contentMatchText(for verdict: VideoVerificationVerdict) -> String {
        switch verdict {
        case .exactMatch: return "정확히 일치"
        case .sameContent: return "동일 콘텐츠"
        case .similarMatch: return "유사 콘텐츠"
        case .registeredButRevoked, .certificateInvalid: return "등록 영상과 일치"
        case .notRegistered: return "등록 기록 없음"
        case .verificationUnavailable: return "확인 불가"
        }
    }

    private func certificateText(for data: VideoVerifyData) -> String {
        if data.vcVerified { return "유효" }
        if data.effectiveVerdict == .certificateInvalid { return "유효하지 않음" }
        return data.videoId == nil ? "해당 없음" : "미발급 또는 미확인"
    }

    private func makeCallout(
        text: String,
        textColor: UIColor,
        backgroundColor: UIColor,
        font: UIFont
    ) -> UIView {
        let container = UIView()
        container.backgroundColor = backgroundColor
        container.layer.cornerRadius = 12

        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = textColor
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        return container
    }

    private func makeDetailRow(label: String, value: String) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fill
        row.alignment = .top
        row.spacing = 16

        let labelView = UILabel()
        labelView.text = label
        labelView.font = .jinBonFont(ofSize: 14)
        labelView.textColor = ColorPalette.secondaryText
        labelView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        labelView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let valueView = UILabel()
        valueView.text = value
        valueView.font = .jinBonFont(ofSize: 14, weight: .medium)
        valueView.textColor = ColorPalette.ink
        valueView.textAlignment = .right
        valueView.numberOfLines = 0

        row.addArrangedSubview(labelView)
        row.addArrangedSubview(valueView)
        return row
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension VideoVerifyViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }
        let provider = result.itemProvider

        if provider.hasItemConformingToTypeIdentifier("public.movie") {
            provider.loadFileRepresentation(forTypeIdentifier: "public.movie") { [weak self] url, error in
                guard let self else { return }
                guard let url else {
                    DispatchQueue.main.async {
                        self.showAlert(error?.localizedDescription ?? "영상을 불러오지 못했습니다. 다시 선택해주세요.")
                    }
                    return
                }

                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(url.pathExtension)
                do {
                    try FileManager.default.copyItem(at: url, to: tempURL)
                } catch {
                    DispatchQueue.main.async {
                        self.showAlert("선택한 영상을 준비하지 못했습니다. 저장 공간을 확인한 뒤 다시 시도해주세요.")
                    }
                    return
                }

                DispatchQueue.main.async {
                    if let previousURL = self.selectedVideoURL {
                        try? FileManager.default.removeItem(at: previousURL)
                    }
                    self.selectedVideoURL = tempURL
                    self.fileNameLabel.text = url.lastPathComponent
                    self.fileNameLabel.isHidden = false

                    self.generateThumbnail(from: tempURL)

                    // 결과 초기화
                    self.resultCard.isHidden = true
                    self.setVerifyButton(enabled: true, title: "영상 검증하기")
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
                    if let selectArea = self?.thumbnailView.superview {
                        selectArea.viewWithTag(100)?.isHidden = true
                        selectArea.viewWithTag(101)?.isHidden = true
                    }
                }
            }
        }
    }
}

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
        let infoText = "영상이 진본인지 확인하세요\n갤러리에서 영상 하나를 선택하면 돼요."
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 7
        let attributedInfo = NSMutableAttributedString(
            string: infoText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 15),
                .foregroundColor: ColorPalette.secondaryText,
                .paragraphStyle: paragraph
            ]
        )
        attributedInfo.addAttributes([
            .font: UIFont.systemFont(ofSize: 19, weight: .bold),
            .foregroundColor: ColorPalette.ink
        ], range: NSRange(location: 0, length: "영상이 진본인지 확인하세요".utf16.count))
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
        verifyButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        verifyButton.backgroundColor = ColorPalette.primary
        verifyButton.setTitleColor(.white, for: .normal)
        verifyButton.layer.cornerRadius = 16
        verifyButton.translatesAutoresizingMaskIntoConstraints = false
        verifyButton.addTarget(self, action: #selector(verifyTapped), for: .touchUpInside)
        verifyButton.heightAnchor.constraint(equalToConstant: 56).isActive = true

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

        verifyButton.isEnabled = false
        verifyButton.setTitle("검증 중...", for: .normal)

        Task {
            do {
                let result = try await JinBonAPIClient.shared.verifyVideo(fileURL: videoURL)
                DispatchQueue.main.async { [weak self] in
                    self?.showResult(result)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.showAlert("검증 실패: \(error.localizedDescription)")
                    self?.verifyButton.isEnabled = true
                    self?.verifyButton.setTitle("영상 검증하기", for: .normal)
                }
            }
        }
    }

    private func showResult(_ data: VideoVerifyData) {
        verifyButton.isEnabled = true
        verifyButton.setTitle("다시 검증", for: .normal)

        resultCard.isHidden = false
        resultCard.subviews.forEach { $0.removeFromSuperview() }

        let isAuthentic = data.authentic
        resultCard.backgroundColor = isAuthentic
            ? UIColor.systemGreen.withAlphaComponent(0.1)
            : UIColor.systemRed.withAlphaComponent(0.1)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        // 결과 아이콘 + 텍스트
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .center

        let icon = UIImageView(image: UIImage(systemName: isAuthentic ? "checkmark.seal.fill" : "xmark.seal.fill"))
        icon.tintColor = isAuthentic ? .systemGreen : .systemRed
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 28).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 28).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = isAuthentic ? "진본 영상입니다" : "진본이 아닌 영상입니다"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = isAuthentic ? .systemGreen : .systemRed

        headerStack.addArrangedSubview(icon)
        headerStack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(headerStack)

        // 상세 정보
        let details: [(String, String)] = [
            ("블록체인 검증", data.blockchainVerified ? "통과" : "실패"),
            ("VC 검증", data.vcVerified ? "통과" : "실패"),
            ("메시지", data.message ?? "-")
        ]

        for (label, value) in details {
            let row = makeDetailRow(label: label, value: value)
            stack.addArrangedSubview(row)
        }

        if let registeredAt = data.registeredAt {
            let row = makeDetailRow(label: "등록일", value: String(registeredAt.prefix(10)))
            stack.addArrangedSubview(row)
        }

        resultCard.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: resultCard.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: resultCard.bottomAnchor, constant: -20)
        ])
    }

    private func makeDetailRow(label: String, value: String) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fill

        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 14)
        labelView.textColor = ColorPalette.secondaryText
        labelView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let valueView = UILabel()
        valueView.text = value
        valueView.font = .systemFont(ofSize: 14, weight: .medium)
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
                guard let url = url else { return }

                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(url.pathExtension)
                try? FileManager.default.copyItem(at: url, to: tempURL)

                DispatchQueue.main.async {
                    self?.selectedVideoURL = tempURL
                    self?.fileNameLabel.text = url.lastPathComponent
                    self?.fileNameLabel.isHidden = false

                    self?.generateThumbnail(from: tempURL)

                    // 결과 초기화
                    self?.resultCard.isHidden = true
                    self?.verifyButton.setTitle("영상 검증하기", for: .normal)
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

/*
 * Copyright 2024 OmniOne.
 * Modifications Copyright 2025-2026 JinBon contributors.
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

import Foundation
import UIKit
import DIDWalletSDK


class SplashViewController: UIViewController {
    
    private var vcOfferPayload: IssueOfferPayload? = nil
    
    public func setVcOffer(vcOfferPayload: IssueOfferPayload) {
        self.vcOfferPayload = vcOfferPayload
    }
    
    private func checkWalletLock() {
        guard Properties.isLoggedIn() else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.navigateToNextViewController()
            }
            return
        }

        // switch screens when wallet type is Lock
        do {
            if try WalletAPI.shared.isLock() {
                // PIN 화면 호출
                let pinVC = Storyboard.pin.instance.instantiateViewController(withIdentifier: ViewControllerID.pincode.rawValue) as! PincodeViewController
                pinVC.modalPresentationStyle = .fullScreen
                pinVC.setRequestType(type: .authenticate(isLock: true))
                pinVC.confirmButtonCompleteClosure = { [self] passcode in
                    self.navigateToNextViewController()
                }
                pinVC.cancelButtonCompleteClosure = { [weak self] in
                    guard let self else { return }
                    PopupUtils.showAlertPopup(title: "Notification", content: "PIN authentication is required to use this app.", VC: self)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.present(pinVC, animated: false, completion: nil)
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.navigateToNextViewController()
                }
            }
        } catch let error as WalletSDKError {
            print("error code: \(error.code), message: \(error.message)")
            PopupUtils.showAlertPopup(title: error.code, content: error.message, VC: self)
        } catch let error as WalletCoreError {
            print("error code: \(error.code), message: \(error.message)")
            PopupUtils.showAlertPopup(title: error.code, content: error.message, VC: self)
        } catch let error as CommunicationSDKError {
            print("error code: \(error.code), message: \(error.message)")
            PopupUtils.showAlertPopup(title: error.code, content: error.message, VC: self)
        } catch {
            print("error :\(error)")
        }
    }
    
    
    private func createWallet() async -> Bool {
                
        // create wallet
        do
        {
            if WalletAPI.shared.isExistWallet() == false {
                // 재설치 시 Keychain에 이전 세션 토큰이 남아있으므로 정리
                JinBonAPIClient.shared.clearLocalSession()
                let created = try await WalletAPI.shared.createWallet(tasURL: URLs.TAS_URL, walletURL: URLs.WALLET_URL)
                print("createWallet: \(created)")
                return created && WalletAPI.shared.isExistWallet()
            }
            return true
        }
        catch
        {
            let (title, message) = ErrorHandler.handle(error)
            
            print("error code: \(title), message: \(message)")
            PopupUtils.showAlertPopup(title: title,
                                      content: message,
                                      VC: self) {
                try? WalletAPI.shared.deleteWallet(deleteAll: true)
            }
            return false
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 단위 테스트 호스트가 실제 TAS에 Wallet을 생성하지 않도록 한다.
        if NSClassFromString("XCTestCase") != nil { return }

        buildJinBonSplashUI()
        
        Properties.generateCaAppId()
        Task { @MainActor in
            guard await createWallet() else { return }
            checkWalletLock()
        }
    }

    private func buildJinBonSplashUI() {
        // Storyboard에 남아 있는 OpenDID 데모 스플래시 대신 진본의 시작 화면과
        // 동일한 색상·타이포그래피를 사용한다.
        view.subviews.forEach { $0.removeFromSuperview() }
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = ColorPalette.canvas

        let mark = UILabel()
        mark.text = "J"
        mark.textAlignment = .center
        mark.font = .jinBonFont(ofSize: 32, weight: .black)
        mark.textColor = .white
        mark.backgroundColor = ColorPalette.primary
        mark.layer.cornerRadius = 20
        mark.clipsToBounds = true

        let brand = UILabel()
        brand.text = "진본"
        brand.textAlignment = .center
        brand.font = .jinBonFont(ofSize: 30, weight: .bold)
        brand.textColor = ColorPalette.ink

        let tagline = UILabel()
        tagline.text = "진짜를 증명하는 가장 간단한 방법"
        tagline.textAlignment = .center
        tagline.font = .jinBonFont(ofSize: 15, weight: .medium)
        tagline.textColor = ColorPalette.secondaryText

        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = ColorPalette.primary
        indicator.startAnimating()

        let status = UILabel()
        status.text = "안전한 Wallet을 준비하고 있어요"
        status.textAlignment = .center
        status.font = .jinBonFont(ofSize: 14, weight: .medium)
        status.textColor = ColorPalette.secondaryText

        let identity = UIStackView(arrangedSubviews: [mark, brand, tagline])
        identity.axis = .vertical
        identity.alignment = .center
        identity.spacing = 10
        identity.setCustomSpacing(18, after: mark)

        let loading = UIStackView(arrangedSubviews: [indicator, status])
        loading.axis = .vertical
        loading.alignment = .center
        loading.spacing = 12

        [identity, loading].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            mark.widthAnchor.constraint(equalToConstant: 64),
            mark.heightAnchor.constraint(equalToConstant: 64),
            identity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            identity.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -42),
            identity.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            identity.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            loading.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loading.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -42)
        ])
    }
    
    private func navigateToNextViewController() {
        guard Properties.isLoggedIn() else {
            let welcome = JinBonWelcomeViewController()
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?
                .changeRootVC(welcome, animated: true)
            return
        }

        Task { @MainActor in
            do {
                // 로컬 완료 플래그 대신 서버 계정과 현재 Holder DID를 대조한다.
                _ = try await JinBonAPIClient.shared.refreshToken()
                Properties.setRegDidDocCompleted(status: true)
                let destination: UIViewController
                if let vcOfferPayload {
                    let issueProfileVC = Storyboard.main.instance.instantiateViewController(withIdentifier: ViewControllerID.issueProfile.rawValue) as! IssueProfileViewController
                    issueProfileVC.setVcOffer(vcOfferPayload: vcOfferPayload)
                    destination = issueProfileVC
                } else {
                    destination = JinBonTabBarController()
                }
                (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?
                    .changeRootVC(destination, animated: false)
            } catch {
                if case JinBonError.notAuthenticated = error {
                    JinBonAPIClient.shared.clearLocalSession()
                    navigateToNextViewController()
                    return
                }
                let alert = UIAlertController(title: "로그인 상태를 확인하지 못했습니다", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "다시 시도", style: .default) { [weak self] _ in
                    self?.navigateToNextViewController()
                })
                alert.addAction(UIAlertAction(title: "다시 로그인", style: .cancel) { [weak self] _ in
                    JinBonAPIClient.shared.clearLocalSession()
                    self?.navigateToNextViewController()
                })
                present(alert, animated: true)
            }
        }
    }
}

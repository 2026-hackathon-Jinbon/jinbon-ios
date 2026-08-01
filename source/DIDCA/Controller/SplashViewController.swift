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

import Foundation
import UIKit
import DIDWalletSDK


class SplashViewController: UIViewController {
    
    private var vcOfferPayload: IssueOfferPayload? = nil
    
    public func setVcOffer(vcOfferPayload: IssueOfferPayload) {
        self.vcOfferPayload = vcOfferPayload
    }
    
    private func checkWalletLock() {
        // switch screens when wallet type is Lock
        do {
            if try WalletAPI.shared.isLock() {
                // PIN 화면 호출
                let pinVC = Storyboard.pin.instance.instantiateViewController(withIdentifier: ViewControllerID.pincode.rawValue) as! PincodeViewController
                pinVC.modalPresentationStyle = .fullScreen
                pinVC.setRequestType(type: .authenticate(isLock: true))
                pinVC.confirmButtonCompleteClosure = { [self] passcode in

                    if let vcOfferPayload {
                        let issueProfileVC = Storyboard.main.instance.instantiateViewController(withIdentifier: ViewControllerID.issueProfile.rawValue) as! IssueProfileViewController
                        issueProfileVC.setVcOffer(vcOfferPayload: vcOfferPayload)
                        issueProfileVC.modalPresentationStyle = .fullScreen
                                
                        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootVC(issueProfileVC, animated: false)
                    } else {
                        
                        // 유저등록 유무
                        if Properties.getSubmitCompleted() == true {
                            let tabBarVC = JinBonTabBarController()
                            tabBarVC.modalPresentationStyle = .fullScreen
                            DispatchQueue.main.async {
                                self.present(tabBarVC, animated: false, completion: nil)
                            }
                        } else {
                            self.navigateToNextViewController()
                        }
                    }
                }
                pinVC.cancelButtonCompleteClosure = { [weak self] in
                    guard let self else { return }
                    PopupUtils.showAlertPopup(title: "Notification", content: "PIN authentication is required to use this app.", VC: self)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    //                DispatchQueue.main.async {
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
        mark.font = .systemFont(ofSize: 32, weight: .black)
        mark.textColor = .white
        mark.backgroundColor = ColorPalette.primary
        mark.layer.cornerRadius = 20
        mark.clipsToBounds = true

        let brand = UILabel()
        brand.text = "진본"
        brand.textAlignment = .center
        brand.font = .systemFont(ofSize: 30, weight: .bold)
        brand.textColor = ColorPalette.ink

        let tagline = UILabel()
        tagline.text = "진짜를 증명하는 가장 간단한 방법"
        tagline.textAlignment = .center
        tagline.font = .systemFont(ofSize: 15, weight: .medium)
        tagline.textColor = ColorPalette.secondaryText

        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = ColorPalette.primary
        indicator.startAnimating()

        let status = UILabel()
        status.text = "안전한 Wallet을 준비하고 있어요"
        status.textAlignment = .center
        status.font = .systemFont(ofSize: 14, weight: .medium)
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
    
        if let vcOfferPayload {
            let issueProfileVC = Storyboard.main.instance.instantiateViewController(withIdentifier: ViewControllerID.issueProfile.rawValue) as! IssueProfileViewController
            issueProfileVC.setVcOffer(vcOfferPayload: vcOfferPayload)
            issueProfileVC.modalPresentationStyle = .fullScreen

            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootVC(issueProfileVC, animated: false)
            return
        }
        
        if Properties.getUserId() == nil {
            let welcome = JinBonWelcomeViewController()
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?
                .changeRootVC(welcome, animated: true)
        } else {
            if Properties.getRegDidDocCompleted() == true {
                let tabBarVC = JinBonTabBarController()
                tabBarVC.modalPresentationStyle = .fullScreen
                DispatchQueue.main.async { self.present(tabBarVC, animated: false, completion: nil) }
            } else {
                
                Task { @MainActor in
                    guard let isAnyKey = try? WalletAPI.shared.isAnyKeysSaved() else {
                        let welcome = JinBonWelcomeViewController()
                        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?
                            .changeRootVC(welcome, animated: true)
                        return
                    }
                    
                    let stepVC = Storyboard.main.instance.instantiateViewController(withIdentifier: ViewControllerID.stepVC.rawValue) as! StepViewController
                    if isAnyKey {
                        
                        try await RegUserProtocol.shared.preProcess()
                        stepVC.setStepType(stepType: StepTypeEnum.STEP_TYPE_3)
                        
                    } else {
                        stepVC.setStepType(stepType: StepTypeEnum.STEP_TYPE_2)
                    }
                    stepVC.modalPresentationStyle = .fullScreen
                    DispatchQueue.main.async { self.present(stepVC, animated: false, completion: nil) }
                }
            }
        }
    }
}

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

public enum StepTypeEnum: String {
    case STEP_TYPE_1 = "Step1"
    case STEP_TYPE_2 = "Step2"
    case STEP_TYPE_3 = "Step3"
}

class StepViewController: UIViewController {
    
    @IBOutlet weak var numImg1: UIButton!
    @IBOutlet weak var numImg2: UIButton!
    @IBOutlet weak var numImg3: UIButton!
    
    @IBOutlet weak var step1Lbl: UILabel!
    @IBOutlet weak var step2Lbl: UILabel!
    @IBOutlet weak var step3Lbl: UILabel!
    
    @IBOutlet weak var lineImg1: UIButton!
    @IBOutlet weak var lineImg2: UIButton!
    
    private var stepType: StepTypeEnum = StepTypeEnum.STEP_TYPE_1
    private let modernTitleLabel = UILabel()
    private let modernDetailLabel = UILabel()
    private let modernStepLabel = UILabel()
    private let modernIconView = UIImageView()
    private let modernActionButton = UIButton(type: .system)
    
    public func setStepType(stepType: StepTypeEnum) {
        self.stepType = stepType
        print("[StepView] next step: \(self.stepType)")
        switch stepType {
        case .STEP_TYPE_1:
            print("1. Register a demo user.\n2. Set the wallet lock type.")
            break
        case .STEP_TYPE_2:
            print("1. Register a PIN to create a signature key.\n2. Register a user DID Document.")
            break
        case .STEP_TYPE_3:
            print("1. Authentication for signing user DID documents.")
            break
        }
    }
    
    private func showUI() {
        
//        self.stopLoading()
        
        let numOneTitle = "01"
        let numOneTitleAttributedString = NSMutableAttributedString(string: numOneTitle)
        let numTwoTitle = "02"
        let numTwoTitleAttributedString = NSMutableAttributedString(string: numTwoTitle)
        let numThreeTitle = "03"
        let numThreeTitleAttributedString = NSMutableAttributedString(string: numThreeTitle)
        
        switch self.stepType {
        case .STEP_TYPE_1:
            step1Lbl.textColor = UIColor(hexCode: "FF8400")
            step2Lbl.textColor = UIColor.black
            step3Lbl.textColor = UIColor.black
            
            numOneTitleAttributedString.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: numOneTitle.count))
            numImg1.setAttributedTitle(numOneTitleAttributedString, for: .normal)
            numImg1.setBackgroundImage(UIImage(named: "property-active"), for: UIControl.State.normal)
            numImg2.setBackgroundImage(UIImage(named: "property-default"), for: UIControl.State.normal)
            numImg3.setBackgroundImage(UIImage(named: "property-default"), for: UIControl.State.normal)
            lineImg1.setImage(UIImage(named: "line_gray"), for: UIControl.State.normal)
            lineImg2.setImage(UIImage(named: "line_gray"), for: UIControl.State.normal)
            break
        case .STEP_TYPE_2:
            step1Lbl.textColor = UIColor.black
            step2Lbl.textColor = UIColor(hexCode: "FF8400")
            step3Lbl.textColor = UIColor.black
            
            numOneTitleAttributedString.addAttribute(.foregroundColor, value: UIColor(hexCode: "FF8400"), range: NSRange(location: 0, length: numOneTitle.count))
            numImg1.setAttributedTitle(numOneTitleAttributedString, for: .normal)
            numImg1.setBackgroundImage(UIImage(named: "property-after"), for: UIControl.State.normal)
            
            numTwoTitleAttributedString.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: numTwoTitle.count))
            numImg2.setAttributedTitle(numTwoTitleAttributedString, for: .normal)
            numImg2.setBackgroundImage(UIImage(named: "property-active"), for: UIControl.State.normal)
            
            numImg3.setBackgroundImage(UIImage(named: "property-default"), for: UIControl.State.normal)
            lineImg1.setImage(UIImage(named: "line_blue"), for: UIControl.State.normal)
            lineImg2.setImage(UIImage(named: "line_gray"), for: UIControl.State.normal)
            break
        case .STEP_TYPE_3:
            step1Lbl.textColor = UIColor.black
            step2Lbl.textColor = UIColor.black
            step3Lbl.textColor = UIColor(hexCode: "FF8400")
            
            numOneTitleAttributedString.addAttribute(.foregroundColor, value: UIColor(hexCode: "FF8400"), range: NSRange(location: 0, length: numOneTitle.count))
            numImg1.setAttributedTitle(numOneTitleAttributedString, for: .normal)
            numImg1.setBackgroundImage(UIImage(named: "property-after"), for: UIControl.State.normal)
            
            numTwoTitleAttributedString.addAttribute(.foregroundColor, value: UIColor(hexCode: "FF8400"), range: NSRange(location: 0, length: numTwoTitle.count))
            numImg2.setAttributedTitle(numTwoTitleAttributedString, for: .normal)
            numImg2.setBackgroundImage(UIImage(named: "property-after"), for: UIControl.State.normal)
            
            numThreeTitleAttributedString.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: numThreeTitle.count))
            numImg3.setAttributedTitle(numThreeTitleAttributedString, for: .normal)
            numImg3.setBackgroundImage(UIImage(named: "property-active"), for: UIControl.State.normal)
            lineImg1.setImage(UIImage(named: "line_blue"), for: UIControl.State.normal)
            lineImg2.setImage(UIImage(named: "line_blue"), for: UIControl.State.normal)
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showUI()
        buildModernUI()
    }

    private func buildModernUI() {
        view.subviews.forEach { $0.isHidden = true }
        view.backgroundColor = ColorPalette.canvas

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content)

        let brand = UILabel()
        brand.text = "JINBON IDENTITY"
        brand.font = .systemFont(ofSize: 12, weight: .bold)
        brand.textColor = ColorPalette.primary

        modernStepLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        modernStepLabel.textColor = ColorPalette.secondaryText
        modernStepLabel.textAlignment = .right

        let header = UIStackView(arrangedSubviews: [brand, modernStepLabel])
        header.axis = .horizontal
        header.distribution = .equalSpacing

        let iconBox = UIView()
        iconBox.backgroundColor = ColorPalette.softBlue
        iconBox.layer.cornerRadius = 32
        iconBox.translatesAutoresizingMaskIntoConstraints = false
        modernIconView.tintColor = ColorPalette.primary
        modernIconView.contentMode = .scaleAspectFit
        modernIconView.translatesAutoresizingMaskIntoConstraints = false
        iconBox.addSubview(modernIconView)

        modernTitleLabel.font = .systemFont(ofSize: 29, weight: .bold)
        modernTitleLabel.textColor = ColorPalette.ink
        modernTitleLabel.numberOfLines = 0
        modernDetailLabel.font = .systemFont(ofSize: 16)
        modernDetailLabel.textColor = ColorPalette.secondaryText
        modernDetailLabel.numberOfLines = 0
        modernDetailLabel.setContentHuggingPriority(.required, for: .vertical)

        let reassurance = makeReassuranceCard()

        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.cornerStyle = .large
        buttonConfig.baseBackgroundColor = ColorPalette.primary
        buttonConfig.baseForegroundColor = .white
        buttonConfig.imagePlacement = .trailing
        buttonConfig.image = UIImage(systemName: "arrow.right")
        buttonConfig.imagePadding = 8
        modernActionButton.configuration = buttonConfig
        modernActionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        modernActionButton.addTarget(self, action: #selector(modernNextTapped), for: .touchUpInside)
        modernActionButton.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let spacer = UIView()
        let stack = UIStackView(arrangedSubviews: [header, iconBox, modernTitleLabel, modernDetailLabel, reassurance, spacer, modernActionButton])
        stack.axis = .vertical
        stack.spacing = 18
        stack.setCustomSpacing(28, after: header)
        stack.setCustomSpacing(22, after: iconBox)
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            content.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 22),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            iconBox.widthAnchor.constraint(equalToConstant: 64),
            iconBox.heightAnchor.constraint(equalToConstant: 64),
            modernIconView.centerXAnchor.constraint(equalTo: iconBox.centerXAnchor),
            modernIconView.centerYAnchor.constraint(equalTo: iconBox.centerYAnchor),
            modernIconView.widthAnchor.constraint(equalToConstant: 30),
            modernIconView.heightAnchor.constraint(equalToConstant: 30)
        ])
        updateModernUI()
    }

    private func makeReassuranceCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.layer.cornerCurve = .continuous
        let icon = UIImageView(image: UIImage(systemName: "lock.shield.fill"))
        icon.tintColor = ColorPalette.success
        icon.translatesAutoresizingMaskIntoConstraints = false
        let label = UILabel()
        label.text = "개인키는 이 기기의 Wallet에만 안전하게 보관되며 진본 서버로 전송되지 않습니다."
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = ColorPalette.secondaryText
        label.numberOfLines = 0
        let row = UIStackView(arrangedSubviews: [icon, label])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 22), icon.heightAnchor.constraint(equalToConstant: 22),
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func updateModernUI() {
        guard isViewLoaded else { return }
        let content: (String, String, String, String, String)
        switch stepType {
        case .STEP_TYPE_1:
            content = ("1 / 3", "person.text.rectangle", "본인 정보를\n확인할게요", "Open DID Wallet에 필요한 기본 정보를 확인합니다. 입력한 정보는 디지털 신원 생성 목적으로만 사용돼요.", "본인 정보 확인하기")
        case .STEP_TYPE_2:
            content = ("2 / 3", "key.fill", "Wallet 보안을\n설정해주세요", "6자리 PIN과 선택적 생체인증으로 DID 개인키를 보호합니다.", "보안 설정하기")
        case .STEP_TYPE_3:
            content = ("3 / 3", "checkmark.seal.fill", "디지털 신원을\n연결할게요", "새 DID Document에 서명하고 진본 계정과 안전하게 연결합니다.", "DID 연결 완료하기")
        }
        modernStepLabel.text = content.0
        modernIconView.image = UIImage(systemName: content.1)
        modernTitleLabel.text = content.2
        modernDetailLabel.text = content.3
        modernActionButton.configuration?.title = content.4
    }

    @objc private func modernNextTapped() {
        nextBtnAction()
    }
    
    private func nextForStep2()
    {
        
        ActivityUtil.show(vc: self){
            try await RegUserProtocol.shared.preProcess()
        } completeClosure: {
            self.registerPin()
        } failureCloseClosure: { title, message in
            PopupUtils.showAlertPopup(title: title,
                                      content: message,
                                      VC: self)
        }
    }
    
    struct VoidResponse : Jsonable {
        init(from jsonData: Data) throws {}
    }
    
    private func nextForStep3() {
        // PIN view
        let pinVC = UIStoryboard.init(name: "PIN", bundle: nil).instantiateViewController(withIdentifier: "PincodeViewController") as! PincodeViewController
        pinVC.modalPresentationStyle = .fullScreen
        pinVC.setRequestType(type: .authenticate(isLock: false))
        pinVC.confirmButtonCompleteClosure = { passcode in
            
            ActivityUtil.show(vc: self){
                let signedDIDDoc = try WalletAPI.shared.createSignedDIDDoc(passcode: passcode)
                // 사용자 등록 요청
                try await RegUserProtocol.shared.process(signedDidDoc: signedDIDDoc)
                
                let didDoc = try WalletAPI.shared.getDidDocument(type: DidDocumentType.HolderDidDocumnet)
                print("holderDidDoc : \(try didDoc.toJson(isPretty: true))")
                
                // out of scope
                let requestJsonData = UpdatePushToken(
                    id: SDKUtils.generateMessageID(),
                    did: didDoc.id,
                    appId: Properties.getCaAppId()!,
                    pushToken: Properties.getPushToken() ?? ""
                )
                
                let urlString = URLs.TAS_URL + "/tas/api/v1/update-push-token"
                let _ : VoidResponse = try await CommunicationClient.sendRequest(urlString: urlString,
                                                                                 requestJsonable: requestJsonData)
                Properties.setRegDidDocCompleted(status: true)
                
            } completeClosure: {
                self.finishJinBonSignup()
            } failureCloseClosure: { title, message in
                PopupUtils.showAlertPopup(title: title,
                                          content: message,
                                          VC: self)
            }
        }
        pinVC.cancelButtonCompleteClosure = {
            PopupUtils.showAlertPopup(title: "Notification", content: "canceled by user", VC: self)
        }
        DispatchQueue.main.async {
            self.present(pinVC, animated: false, completion: nil)
        }
    }

    private func finishJinBonSignup() {
        guard Properties.getSignupToken() != nil || Properties.getDidRebindToken() != nil else {
            goMainView()
            return
        }
        Task {
            do {
                let didDoc = try WalletAPI.shared.getDidDocument(type: DidDocumentType.HolderDidDocumnet)
                if let rebindToken = Properties.getDidRebindToken() {
                    _ = try await JinBonAPIClient.shared.rebindDid(didRebindToken: rebindToken, did: didDoc.id)
                    Properties.clearDidRebindToken()
                } else if let signupToken = Properties.getSignupToken() {
                    _ = try await JinBonAPIClient.shared.completeSignup(signupToken: signupToken, did: didDoc.id)
                    Properties.clearSignupToken()
                }
                await MainActor.run { self.goJinBonMain() }
            } catch {
                await MainActor.run {
                    let title = Properties.getDidRebindToken() == nil ? "회원가입 완료 실패" : "디지털 신원 재연결 실패"
                    PopupUtils.showAlertPopup(title: title,
                                              content: error.localizedDescription, VC: self)
                }
            }
        }
    }

    private func goJinBonMain() {
        let tab = JinBonTabBarController()
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootVC(tab, animated: true)
    }
    
    func registerPin()
    {
        let pinVC = UIStoryboard.init(name: "PIN", bundle: nil).instantiateViewController(withIdentifier: "PincodeViewController") as! PincodeViewController
        pinVC.modalPresentationStyle = .fullScreen
        pinVC.setRequestType(type: .register(isLock: false))
        pinVC.confirmButtonCompleteClosure = { passcode in
            
            ActivityUtil.show(vc: self){
                try WalletAPI.shared.generateKeyPair(hWalletToken: RegUserProtocol.shared.getWalletToken(), keyId: KeyIds.keyagree, algType: AlgorithmType.secp256r1)
                // register PIN
                try WalletAPI.shared.generateKeyPair(hWalletToken: RegUserProtocol.shared.getWalletToken(), passcode: passcode, keyId: KeyIds.pin, algType: AlgorithmType.secp256r1)
            } completeClosure: {
                self.doNext()
            } failureCloseClosure: { title, message in
                PopupUtils.showAlertPopup(title: title,
                                          content: message,
                                          VC: self)
            }
        }
        pinVC.cancelButtonCompleteClosure = {
            PopupUtils.showAlertPopup(title: "Notification", content: "canceled by user", VC: self)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.present(pinVC, animated: false, completion: nil)
        }
    }
    
    @IBAction func nextBtnAction() {
        
        
        switch self.stepType {
        /**
            1. Register a demo user
            2. Set the wallet lock type
         */
        case .STEP_TYPE_1:
            showUserRegWebView()
            break
        /**
            1. Register a pin to create a signature key
            2. Register a user DID Document
         */
        case .STEP_TYPE_2:
            nextForStep2()
            break
        case .STEP_TYPE_3:
            nextForStep3()
            break
        }
    }
    
    private func doNext() {
         
        let popupVC = UIStoryboard.init(name: "Popup", bundle: nil).instantiateViewController(withIdentifier: "TwoButtonDialogViewController") as! TwoButtonDialogViewController
        popupVC.modalPresentationStyle = .overCurrentContext
        popupVC.setContentsMessage(message: "Would you like to additionally register biometric authentication?")
        popupVC.confirmButtonCompleteClosure = { [self] in
            ActivityUtil.show(vc: self){
                // register BIO
                _ = try WalletAPI.shared.generateKeyPair(hWalletToken: RegUserProtocol.shared.getWalletToken(), keyId: KeyIds.bio, algType: AlgorithmType.secp256r1, promptMsg: "Authenticate to access your private key")
                try WalletAPI.shared.createHolderDIDDocument(hWalletToken: RegUserProtocol.shared.getWalletToken())
            } completeClosure: {
                self.presentSubmitViewController()
            } failureCloseClosure: { title, message in
                PopupUtils.showAlertPopup(title: title,
                                          content: message,
                                          VC: self)
            }
        }
        popupVC.cancelButtonCompleteClosure = { [self] in
            ActivityUtil.show(vc: self){
                try WalletAPI.shared.createHolderDIDDocument(hWalletToken: RegUserProtocol.shared.getWalletToken())
            } completeClosure: {
                self.presentSubmitViewController()
            } failureCloseClosure: { title, message in
                PopupUtils.showAlertPopup(title: title,
                                          content: message,
                                          VC: self)
            }
            
        }
        DispatchQueue.main.async {
//            self.stopLoading()
            self.present(popupVC, animated: false, completion: nil) }
    }
    
    private func presentSubmitViewController() {
        self.setStepType(stepType: StepTypeEnum.STEP_TYPE_3)
        showUI()
        updateModernUI()
    }
}

//Move to other viewController
extension StepViewController
{
    func showUserRegWebView()
    {
        let stepVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserRegWebViewController") as! UserRegWebViewController
        stepVC.modalPresentationStyle = .fullScreen
        DispatchQueue.main.async {

            self.present(stepVC, animated: false, completion: nil)
        }
    }
    
    func goMainView()
    {
        let submitVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        submitVC.modalPresentationStyle = .fullScreen
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.present(submitVC, animated: false)
        }
    }
}

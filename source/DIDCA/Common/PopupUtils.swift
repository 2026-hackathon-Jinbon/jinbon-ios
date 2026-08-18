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

import UIKit

public class PopupUtils {
    static public func showAlertPopup(title:String,
                                      content: String,
                                      VC: UIViewController,
                                      completeClosure : (()->Void)? = nil)
    {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let popupVC = Storyboard.popup.instance.instantiateViewController(withIdentifier: ViewControllerID.errorDialog.rawValue) as! ErrorDialogViewController
        popupVC.modalPresentationStyle = .overCurrentContext
        popupVC.setTitleMessage(message: normalizedTitle.isEmpty
                                ? "등록 보증서 발급에 실패했습니다"
                                : normalizedTitle)
        popupVC.setContentsMessage(message: normalizedContent.isEmpty
                                   ? "오류 정보를 확인할 수 없습니다. 잠시 후 다시 시도해주세요."
                                   : normalizedContent)
        popupVC.confirmButtonCompleteClosure = completeClosure
        DispatchQueue.main.async {
            visiblePresenter(from: VC).present(popupVC, animated: false, completion: nil)
        }
    }

    private static func visiblePresenter(from requested: UIViewController) -> UIViewController {
        let base: UIViewController
        if requested.viewIfLoaded?.window != nil {
            base = requested
        } else {
            base = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)?
                .rootViewController ?? requested
        }

        if let presented = base.presentedViewController {
            return visiblePresenter(from: presented)
        }
        if let navigation = base as? UINavigationController,
           let visible = navigation.visibleViewController {
            return visiblePresenter(from: visible)
        }
        if let tab = base as? UITabBarController,
           let selected = tab.selectedViewController {
            return visiblePresenter(from: selected)
        }
        return base
    }
    
    static public func showDialogPopup(title:String, content: String, VC: UIViewController) {
        let popupVC = Storyboard.popup.instance.instantiateViewController(withIdentifier: ViewControllerID.oneButtonDialog.rawValue) as! OneButtonDialogViewController
        popupVC.modalPresentationStyle = .overCurrentContext
        popupVC.setTitleMessage(message: title)
        popupVC.setContentsMessage(message: content)
        popupVC.confirmButtonCompleteClosure = {}
        DispatchQueue.main.async {
            VC.present(popupVC, animated: false, completion: nil) }
    }
    
    static public func showInputPopUp(title: String, subtitle : String, VC: UIViewController, completeClosure : @escaping ((String)->Void))
    {
        let popupVC = Storyboard.popup.instance.instantiateViewController(withIdentifier: ViewControllerID.inputPopUp.rawValue) as! InputPopUpViewController
        popupVC.modalPresentationStyle = .overCurrentContext
        popupVC.setTitleText(titleText: title)
        popupVC.setSubtitleText(subtitleText: subtitle)
        popupVC.confirmButtonCompleteClosure = completeClosure
        
        DispatchQueue.main.async {
            VC.present(popupVC, animated: false, completion: nil) }
    }
}

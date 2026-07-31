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

class TwoButtonDialogViewController: UIViewController {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var contentsLbl: UILabel!
    
    private var contentsMessage = ""
    private var titleMessage = "Confirm"
    
    var confirmButtonCompleteClosure:(()->Void)?
    var cancelButtonCompleteClosure:(()->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mainView.backgroundColor = .white
        mainView.layer.cornerRadius = 22
        mainView.layer.cornerCurve = .continuous

        contentsLbl.attributedText = nil
        contentsLbl.text = contentsMessage
        contentsLbl.textColor = ColorPalette.ink
        contentsLbl.font = .jinBonFont(ofSize: 17, weight: .semibold)
        contentsLbl.textAlignment = .center
        contentsLbl.numberOfLines = 0

        cancelButton.setTitle("아니요", for: .normal)
        cancelButton.setTitleColor(ColorPalette.primary, for: .normal)
        cancelButton.titleLabel?.font = .jinBonFont(ofSize: 16, weight: .bold)
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = ColorPalette.primary.cgColor

        confirmButton.setTitle("설정하기", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = .jinBonFont(ofSize: 16, weight: .bold)
        confirmButton.backgroundColor = ColorPalette.primary
    }
    
    public func setContentsMessage(message: String) {
        self.contentsMessage = message
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        if let cancelButtonCompleteClosure = cancelButtonCompleteClosure {
            cancelButtonCompleteClosure()
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @IBAction func yesButtonAction(_ sender: Any) {
        if let confirmButtonCompleteClosure = confirmButtonCompleteClosure {
            confirmButtonCompleteClosure()
            self.dismiss(animated: false, completion: nil)
        }
    }
}

//
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

@IBDesignable
class RoundedButton : UIButton
{
    static let defaultRadius: CGFloat = 14
    
    @IBInspectable var cornerRadius: CGFloat = defaultRadius {
        didSet {
            layer.cornerRadius = cornerRadius
        }}
    
    @IBInspectable var borderWidth : CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor : UIColor = ColorPalette.primary {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(
                withDuration: 0.14,
                delay: 0,
                options: [.allowUserInteraction, .beginFromCurrentState]
            ) {
                self.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.98, y: 0.98)
                    : .identity
                self.alpha = self.isHighlighted ? 0.9 : (self.isEnabled ? 1 : 0.55)
            }
        }
    }

    override var isEnabled: Bool {
        didSet { alpha = isEnabled ? 1 : 0.55 }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerCurve = .continuous
        titleLabel?.font = .jinBonFont(ofSize: titleLabel?.font.pointSize ?? 16, weight: .bold)
        titleLabel?.adjustsFontForContentSizeCategory = true
    }
}

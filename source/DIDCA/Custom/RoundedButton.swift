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
import ObjectiveC.runtime

enum ButtonPressFeedback {
    static func install() {
        let originalSelector = NSSelectorFromString("setHighlighted:")
        let feedbackSelector = #selector(UIButton.jinBonSetHighlighted(_:))

        guard
            let originalMethod = class_getInstanceMethod(UIButton.self, originalSelector),
            let feedbackMethod = class_getInstanceMethod(UIButton.self, feedbackSelector)
        else { return }

        method_exchangeImplementations(originalMethod, feedbackMethod)
    }
}

private extension UIButton {
    @objc func jinBonSetHighlighted(_ highlighted: Bool) {
        let wasHighlighted = isHighlighted
        jinBonSetHighlighted(highlighted)

        guard wasHighlighted != highlighted else { return }

        if highlighted {
            layer.removeAllAnimations()
            transform = UIAccessibility.isReduceMotionEnabled
                ? .identity
                : CGAffineTransform(scaleX: 0.92, y: 0.92)
            alpha = 0.55
            return
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIView.animate(
            withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.18,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.4,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.transform = .identity
            self.alpha = self.isEnabled ? 1 : 0.55
        }
    }
}

class PressFeedbackButton: UIButton {}

@IBDesignable
class RoundedButton : PressFeedbackButton
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

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerCurve = .continuous
        titleLabel?.font = .jinBonFont(ofSize: titleLabel?.font.pointSize ?? 16, weight: .bold)
        titleLabel?.adjustsFontForContentSizeCategory = true
    }
}

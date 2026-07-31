//
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

struct ColorPalette
{
    static let primary = UIColor(hexCode: "2457E6")
    static let primaryPressed = UIColor(hexCode: "1943BE")
    static let ink = UIColor(hexCode: "111827")
    // 흰색/캔버스 배경 모두에서 작은 본문이 선명하게 읽히는 중성색
    static let secondaryText = UIColor(hexCode: "475467")
    static let canvas = UIColor(hexCode: "F7F8FC")
    static let success = UIColor(hexCode: "12B76A")
    static let card = UIColor.white
    static let warning = UIColor(hexCode: "F79009")
    static let danger = UIColor(hexCode: "F04438")
    static let divider = UIColor(hexCode: "EAECF0")
    static let softBlue = UIColor(hexCode: "EEF4FF")
    static let disabled = UIColor(hexCode: "D0D5DD")
    static let elevatedShadow = UIColor(hexCode: "101828")
}

enum JinBonTypography {
    static func font(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let name: String
        if weight.rawValue <= UIFont.Weight.light.rawValue {
            name = "SUIT-Light"
        } else if weight.rawValue < UIFont.Weight.medium.rawValue {
            name = "SUIT-Regular"
        } else if weight.rawValue < UIFont.Weight.semibold.rawValue {
            name = "SUIT-Medium"
        } else if weight.rawValue < UIFont.Weight.bold.rawValue {
            name = "SUIT-SemiBold"
        } else if weight.rawValue < UIFont.Weight.heavy.rawValue {
            name = "SUIT-Bold"
        } else {
            name = "SUIT-Heavy"
        }
        let base = UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size, weight: weight)
        return UIFontMetrics.default.scaledFont(for: base)
    }
}

extension UIFont {
    static func jinBonFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        JinBonTypography.font(ofSize: size, weight: weight)
    }
}

enum JinBonTheme {
    static func apply() {
        UIView.appearance().tintColor = ColorPalette.primary

        let navigation = UINavigationBarAppearance()
        navigation.configureWithOpaqueBackground()
        navigation.backgroundColor = ColorPalette.canvas
        navigation.shadowColor = .clear
        navigation.titleTextAttributes = [
            .font: UIFont.jinBonFont(ofSize: 17, weight: .bold),
            .foregroundColor: ColorPalette.ink
        ]
        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = navigation
        navigationBar.scrollEdgeAppearance = navigation
        navigationBar.compactAppearance = navigation
        navigationBar.tintColor = ColorPalette.primary

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = ColorPalette.card
        tab.shadowColor = ColorPalette.divider
        configure(tab.stackedLayoutAppearance)
        configure(tab.inlineLayoutAppearance)
        configure(tab.compactInlineLayoutAppearance)
        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tab
        if #available(iOS 15.0, *) { tabBar.scrollEdgeAppearance = tab }

        UITableView.appearance().separatorColor = ColorPalette.divider
        UITableView.appearance().backgroundColor = ColorPalette.canvas
        UITextField.appearance().tintColor = ColorPalette.primary
        UISwitch.appearance().onTintColor = ColorPalette.primary
        UIPageControl.appearance().currentPageIndicatorTintColor = ColorPalette.primary
        UIPageControl.appearance().pageIndicatorTintColor = ColorPalette.disabled
    }

    private static func configure(_ appearance: UITabBarItemAppearance) {
        appearance.normal.iconColor = ColorPalette.secondaryText
        appearance.normal.titleTextAttributes = [
            .font: UIFont.jinBonFont(ofSize: 11, weight: .medium),
            .foregroundColor: ColorPalette.secondaryText
        ]
        appearance.selected.iconColor = ColorPalette.primary
        appearance.selected.titleTextAttributes = [
            .font: UIFont.jinBonFont(ofSize: 11, weight: .bold),
            .foregroundColor: ColorPalette.primary
        ]
    }
}

extension UILabel {
    /// 여러 줄 본문에 일관된 호흡을 제공한다. 호출 전에 font/textColor를 설정한다.
    func setJinBonText(_ value: String, lineSpacing: CGFloat = 5) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        style.alignment = textAlignment
        attributedText = NSAttributedString(
            string: value,
            attributes: [
                .font: font as Any,
                .foregroundColor: textColor as Any,
                .paragraphStyle: style
            ]
        )
        adjustsFontForContentSizeCategory = true
    }
}

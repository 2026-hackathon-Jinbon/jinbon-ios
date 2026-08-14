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

class JinBonTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTabs()
        setupAppearance()
    }

    private func setupTabs() {
        let homeNav = UINavigationController(rootViewController: JinBonHomeViewController())
        homeNav.tabBarItem = UITabBarItem(
            title: "홈",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        let videosNav = UINavigationController(rootViewController: VideoListViewController())
        videosNav.tabBarItem = UITabBarItem(
            title: "내 영상",
            image: UIImage(systemName: "play.rectangle.on.rectangle"),
            selectedImage: UIImage(systemName: "play.rectangle.on.rectangle.fill")
        )

        let certificateNav = UINavigationController(rootViewController: JinBonCertificateViewController())
        certificateNav.tabBarItem = UITabBarItem(
            title: "보증서",
            image: UIImage(systemName: "checkmark.seal"),
            selectedImage: UIImage(systemName: "checkmark.seal.fill")
        )

        let settingsNav = UINavigationController(rootViewController: JinBonSettingsViewController())
        settingsNav.tabBarItem = UITabBarItem(
            title: "설정",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )

        viewControllers = [homeNav, videosNav, certificateNav, settingsNav]
    }

    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ColorPalette.card
        appearance.shadowColor = ColorPalette.divider

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.selected.iconColor = ColorPalette.primary
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: ColorPalette.primary]
        itemAppearance.normal.iconColor = .systemGray
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}

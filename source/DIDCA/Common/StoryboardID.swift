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

// MARK: - Storyboard 이름
enum Storyboard: String {
    case main = "Main"
    case pin = "PIN"
    case popup = "Popup"
    case zkp = "ZKP"

    var instance: UIStoryboard {
        UIStoryboard(name: rawValue, bundle: nil)
    }
}

// MARK: - ViewController Identifier
enum ViewControllerID: String {
    // Main
    case splash = "SplashViewController"
    case main = "MainViewController"
    case stepVC = "StepViewController"
    case addVc = "AddVcViewController"
    case qrScan = "QRScanViewController"
    case setting = "SettingViewController"
    case authSetting = "AuthSettingViewController"
    case selectAuth = "SelectAuthViewController"
    case issueProfile = "IssueProfileViewController"
    case issueVCWeb = "IssueVCWebViewController"
    case issueCompleted = "IssueCompletedViewController"
    case verifyProfile = "VerifyProfileViewController"
    case verifyCompleted = "VerifyCompletedViewController"
    case vcDetail = "VCDetailViewController"
    case userRegWeb = "UserRegWebViewController"
    case jinBonSettings = "JinBonSettingsViewController"

    // PIN
    case pincode = "PincodeViewController"

    // Popup
    case errorDialog = "ErrorDialogViewController"
    case oneButtonDialog = "OneButtonDialogViewController"
    case twoButtonDialog = "TwoButtonDialogViewController"
    case inputPopUp = "InputPopUpViewController"
    case activityIndicator = "ActivityIndicatorViewController"

    // ZKP
    case zkpSubmission = "ZKPSubmissionViewController"
    case attrSelection = "AttrSelectionViewController"
}

// MARK: - Cell Reuse Identifier
enum CellID: String {
    // TableView
    case settingCell = "SettingCell"
    case chevronCell = "ChevronCell"
    case authTypeCell = "AuthTypeCell"
    case videoCell = "VideoCell"
    case imageCell = "imageCell"
    case stringCell = "stringCell"
    case certificate = "certificate"
    case attrSelectionCell = "attrSelectionCell"
    case zkpSubmissionCell = "zkpSubmissionCell"
    case zkpSubmissionTextCell = "zkpSubmissionTextCell"

    // CollectionView
    case addVCCell = "AddVCCell"
    case mainVCCell = "mainVCCell"
}

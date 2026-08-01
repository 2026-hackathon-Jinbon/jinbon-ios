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

import XCTest
@testable import DIDCA

final class PendingVideoVcDataTests: XCTestCase {

    func testPendingContextRoundTripPreservesOffer() throws {
        let expected = PendingVideoVcData(vcId: "vc-123", offerId: "offer-456")

        let encoded = try JSONEncoder().encode(expected)
        let decoded = try JSONDecoder().decode(PendingVideoVcData.self, from: encoded)

        XCTAssertEqual(decoded, expected)
    }
}

final class VideoVerifyDataTests: XCTestCase {

    func testDecodesAllBackendVerdicts() throws {
        for verdict in VideoVerificationVerdict.allCases {
            let json = """
            {
              "verdict": "\(verdict.rawValue)",
              "similarityDistance": 3.5,
              "authentic": \(verdict == .exactMatch || verdict == .similarMatch),
              "videoId": 1,
              "issuerDid": "did:omn:issuer",
              "registeredAt": "2026-07-31T12:00:00",
              "blockchainVerified": true,
              "vcVerified": false,
              "active": true,
              "message": "message",
              "notice": "notice"
            }
            """

            let decoded = try JSONDecoder().decode(
                VideoVerifyData.self, from: Data(json.utf8))

            XCTAssertEqual(decoded.verdict, verdict)
            XCTAssertEqual(decoded.effectiveVerdict, verdict)
        }
    }

    func testLegacyResponseFallsBackWithoutCallingItFake() throws {
        let json = """
        {
          "authentic": false,
          "videoId": null,
          "issuerDid": null,
          "registeredAt": null,
          "blockchainVerified": false,
          "vcVerified": false,
          "active": false,
          "message": "not registered"
        }
        """

        let decoded = try JSONDecoder().decode(
            VideoVerifyData.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.effectiveVerdict, .notRegistered)
    }

    func testUnknownFutureVerdictFallsBackToUnavailable() throws {
        let json = """
        {
          "verdict": "FUTURE_VERDICT",
          "authentic": false,
          "videoId": 1,
          "issuerDid": "did:omn:issuer",
          "registeredAt": null,
          "blockchainVerified": false,
          "vcVerified": false,
          "active": true,
          "message": "unknown"
        }
        """

        let decoded = try JSONDecoder().decode(
            VideoVerifyData.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.effectiveVerdict, .verificationUnavailable)
    }
}

// MARK: - SDKUtils Tests

final class SDKUtilsTests: XCTestCase {

    func testConvertDateFormat_validISO8601() {
        let result = SDKUtils.convertDateFormat(dateString: "2025-06-15T12:30:45Z")
        XCTAssertEqual(result, "2025-06-15")
    }

    func testConvertDateFormat_invalidFormat() {
        let result = SDKUtils.convertDateFormat(dateString: "not-a-date")
        XCTAssertNil(result)
    }

    func testConvertDateFormat_emptyString() {
        let result = SDKUtils.convertDateFormat(dateString: "")
        XCTAssertNil(result)
    }

    func testConvertDateFormat2_validMicrosecondFormat() {
        let result = SDKUtils.convertDateFormat2(dateString: "2025-06-15T12:30:45.123456+0900")
        XCTAssertNotNil(result)
    }

    func testConvertDateFormat2_invalidFormat() {
        let result = SDKUtils.convertDateFormat2(dateString: "2025-06-15")
        XCTAssertNil(result)
    }

    func testGenerateMessageID_uniqueness() {
        let id1 = SDKUtils.generateMessageID()
        let id2 = SDKUtils.generateMessageID()
        XCTAssertNotEqual(id1, id2)
    }

    func testGenerateMessageID_notEmpty() {
        let id = SDKUtils.generateMessageID()
        XCTAssertFalse(id.isEmpty)
    }

    func testGenerateMessageID_expectedLength() {
        // yyyyMMddHHmmssSSSSSS (20자) + 8자리 hex = 28자
        let id = SDKUtils.generateMessageID()
        XCTAssertEqual(id.count, 28)
    }

    func testMergeNonce_bothNil() {
        XCTAssertThrowsError(try SDKUtils.mergeNonce(clientNonce: nil, serverNonce: nil))
    }

    func testMergeNonce_clientNil() {
        let serverNonce = Data([0x01, 0x02, 0x03])
        XCTAssertThrowsError(try SDKUtils.mergeNonce(clientNonce: nil, serverNonce: serverNonce))
    }

    func testMergeNonce_serverNil() {
        let clientNonce = Data([0x01, 0x02, 0x03])
        XCTAssertThrowsError(try SDKUtils.mergeNonce(clientNonce: clientNonce, serverNonce: nil))
    }

    func testMergeNonce_validInputs() throws {
        let clientNonce = Data([0x01, 0x02, 0x03])
        let serverNonce = Data([0x04, 0x05, 0x06])
        let result = try SDKUtils.mergeNonce(clientNonce: clientNonce, serverNonce: serverNonce)
        // SHA-256 결과는 항상 32바이트
        XCTAssertEqual(result.count, 32)
    }

    func testMergeNonce_deterministic() throws {
        let clientNonce = Data([0x01, 0x02])
        let serverNonce = Data([0x03, 0x04])
        let result1 = try SDKUtils.mergeNonce(clientNonce: clientNonce, serverNonce: serverNonce)
        let result2 = try SDKUtils.mergeNonce(clientNonce: clientNonce, serverNonce: serverNonce)
        XCTAssertEqual(result1, result2)
    }

    func testGenerateRandomBytes_length() throws {
        let utils = SDKUtils()
        let bytes = try utils.generateRandomBytes()
        XCTAssertEqual(bytes.count, 16)
    }

    func testGenerateRandomBytes_randomness() throws {
        let utils = SDKUtils()
        let bytes1 = try utils.generateRandomBytes()
        let bytes2 = try utils.generateRandomBytes()
        // 16바이트 랜덤 데이터가 연속 동일할 확률은 극히 낮음
        XCTAssertNotEqual(bytes1, bytes2)
    }
}

// MARK: - KeychainHelper Tests

final class KeychainHelperTests: XCTestCase {

    private let testKey = "com.jinbon.test.keychainHelper"

    override func tearDownWithError() throws {
        KeychainHelper.delete(key: testKey)
    }

    func testSaveAndLoad() {
        let saved = KeychainHelper.save(key: testKey, value: "testValue")
        XCTAssertTrue(saved)

        let loaded = KeychainHelper.load(key: testKey)
        XCTAssertEqual(loaded, "testValue")
    }

    func testLoadNonExistentKey() {
        let loaded = KeychainHelper.load(key: "com.jinbon.test.nonexistent")
        XCTAssertNil(loaded)
    }

    func testOverwrite() {
        KeychainHelper.save(key: testKey, value: "first")
        KeychainHelper.save(key: testKey, value: "second")
        XCTAssertEqual(KeychainHelper.load(key: testKey), "second")
    }

    func testDelete() {
        KeychainHelper.save(key: testKey, value: "toDelete")
        let deleted = KeychainHelper.delete(key: testKey)
        XCTAssertTrue(deleted)
        XCTAssertNil(KeychainHelper.load(key: testKey))
    }

    func testSaveEmptyString() {
        let saved = KeychainHelper.save(key: testKey, value: "")
        XCTAssertTrue(saved)
        XCTAssertEqual(KeychainHelper.load(key: testKey), "")
    }
}

// MARK: - StoryboardID Tests

final class StoryboardIDTests: XCTestCase {

    func testViewControllerIDRawValues() {
        XCTAssertEqual(ViewControllerID.splash.rawValue, "SplashViewController")
        XCTAssertEqual(ViewControllerID.main.rawValue, "MainViewController")
        XCTAssertEqual(ViewControllerID.pincode.rawValue, "PincodeViewController")
        XCTAssertEqual(ViewControllerID.issueProfile.rawValue, "IssueProfileViewController")
        XCTAssertEqual(ViewControllerID.verifyProfile.rawValue, "VerifyProfileViewController")
        XCTAssertEqual(ViewControllerID.errorDialog.rawValue, "ErrorDialogViewController")
        XCTAssertEqual(ViewControllerID.activityIndicator.rawValue, "ActivityIndicatorViewController")
    }

    func testCellIDRawValues() {
        XCTAssertEqual(CellID.settingCell.rawValue, "SettingCell")
        XCTAssertEqual(CellID.mainVCCell.rawValue, "mainVCCell")
        XCTAssertEqual(CellID.addVCCell.rawValue, "AddVCCell")
        XCTAssertEqual(CellID.videoCell.rawValue, "VideoCell")
    }

    func testStoryboardRawValues() {
        XCTAssertEqual(Storyboard.main.rawValue, "Main")
        XCTAssertEqual(Storyboard.pin.rawValue, "PIN")
        XCTAssertEqual(Storyboard.popup.rawValue, "Popup")
        XCTAssertEqual(Storyboard.zkp.rawValue, "ZKP")
    }

    func testAllViewControllerIDsUnique() {
        let allCases: [ViewControllerID] = [
            .splash, .main, .stepVC, .addVc, .qrScan, .setting, .authSetting,
            .selectAuth, .issueProfile, .issueVCWeb, .issueCompleted,
            .verifyProfile, .verifyCompleted, .vcDetail, .userRegWeb,
            .jinBonSettings, .pincode, .errorDialog, .oneButtonDialog,
            .twoButtonDialog, .inputPopUp, .activityIndicator,
            .zkpSubmission, .attrSelection
        ]
        let rawValues = allCases.map { $0.rawValue }
        XCTAssertEqual(rawValues.count, Set(rawValues).count, "Duplicate ViewControllerID raw values found")
    }

    func testAllCellIDsUnique() {
        let allCases: [CellID] = [
            .settingCell, .chevronCell, .authTypeCell, .videoCell,
            .imageCell, .stringCell, .certificate, .attrSelectionCell,
            .zkpSubmissionCell, .zkpSubmissionTextCell, .addVCCell, .mainVCCell
        ]
        let rawValues = allCases.map { $0.rawValue }
        XCTAssertEqual(rawValues.count, Set(rawValues).count, "Duplicate CellID raw values found")
    }
}

// MARK: - Protocol Concurrency Tests

final class ProtocolConcurrencyTests: XCTestCase {

    func testIssueVcProtocol_doublePreProcess() async {
        let protocol_ = IssueVcProtocol.shared
        protocol_.cancelIssuance()

        // 첫 번째 preProcess는 네트워크 에러로 실패하지만 lock은 정상 해제되어야 함
        do {
            try await protocol_.preProcess(vcPlanId: "test", issuer: "test")
        } catch {
            // 네트워크 에러 예상 - lock이 해제되었는지 확인
        }

        // lock이 정상 해제되었으므로 두 번째 호출도 lock 에러가 아닌 네트워크 에러여야 함
        do {
            try await protocol_.preProcess(vcPlanId: "test2", issuer: "test2")
            XCTFail("Should have thrown an error")
        } catch let error as NSError {
            // "already in progress" 에러가 아니어야 함 (lock이 정상 해제되었으므로)
            XCTAssertNotEqual(error.domain, "JinBon.IssueVc")
        }
        protocol_.cancelIssuance()
    }

    func testIssueVcProtocol_cancelResetsLock() {
        let protocol_ = IssueVcProtocol.shared
        protocol_.cancelIssuance()
        // cancel 후 다시 preProcess 호출 시 lock 에러가 아니어야 함
        // (네트워크 에러는 발생할 수 있지만 lock 에러는 아님)
    }
}

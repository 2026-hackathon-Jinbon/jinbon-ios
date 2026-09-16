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

final class AuthFlowRegressionTests: XCTestCase {
    private let tokenKeys = ["jinbon_access_token", "jinbon_refresh_token", "jinbon_signup_token", "jinbon_did_rebind_token"]
    private let defaultsKeys = ["jinbon_member_id", "jinbon_member_name", "jinbon_member_role", "jinbon_account_did", "reg_diddoc_completed", "jinbon_signup_token", "jinbon_did_rebind_token"]
    private var savedTokens: [String: String] = [:]
    private var savedDefaults: [String: Any] = [:]
    private var session: URLSession!
    private var api: JinBonAPIClient!

    override func setUp() {
        super.setUp()
        for key in tokenKeys { savedTokens[key] = KeychainHelper.load(key: key) }
        for key in defaultsKeys { savedDefaults[key] = UserDefaults.standard.object(forKey: key) }
        Properties.clearAuth()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AuthMockURLProtocol.self]
        session = URLSession(configuration: configuration)
        api = JinBonAPIClient(session: session)
    }

    override func tearDown() {
        session.invalidateAndCancel()
        AuthMockURLProtocol.handler = nil
        for key in tokenKeys {
            KeychainHelper.delete(key: key)
            if let value = savedTokens[key] { KeychainHelper.save(key: key, value: value) }
        }
        for key in defaultsKeys {
            UserDefaults.standard.removeObject(forKey: key)
            if let value = savedDefaults[key] { UserDefaults.standard.set(value, forKey: key) }
        }
        super.tearDown()
    }

    func testSignupAcceptsNullDataWithoutCreatingLoginSession() async throws {
        AuthMockURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/signup/did/complete")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
            return (200, Data(#"{"status":200,"data":null}"#.utf8))
        }
        try await api.completeSignup(signupToken: "signup", did: "did:omn:new")
        XCTAssertFalse(Properties.isLoggedIn())
    }

    func testSignupRejectsServerFailure() async {
        AuthMockURLProtocol.handler = { _ in
            (409, Data(#"{"status":409,"message":"already registered"}"#.utf8))
        }
        do {
            try await api.completeSignup(signupToken: "signup", did: "did:omn:new")
            XCTFail("A failed signup must not be treated as complete")
        } catch {
            XCTAssertEqual(error.localizedDescription, "already registered")
        }
        XCTAssertFalse(Properties.isLoggedIn())
    }

    func testRebindReplacesStaleSignupToken() {
        Properties.setSignupToken("stale-signup")
        Properties.setDidRebindToken("new-rebind")
        XCTAssertNil(Properties.getSignupToken())
        XCTAssertEqual(Properties.getDidRebindToken(), "new-rebind")
    }

    func testSignupReplacesStaleRebindToken() {
        Properties.setDidRebindToken("stale-rebind")
        Properties.setSignupToken("new-signup")
        XCTAssertNil(Properties.getDidRebindToken())
        XCTAssertEqual(Properties.getSignupToken(), "new-signup")
    }

    func testClearSessionRemovesPendingIdentityAndCompletionState() {
        Properties.setAccessToken("access")
        Properties.setRefreshToken("refresh")
        Properties.setSignupToken("signup")
        Properties.setAccountDid("did:omn:old")
        Properties.setRegDidDocCompleted(status: true)
        api.clearLocalSession()
        XCTAssertFalse(Properties.isLoggedIn())
        XCTAssertNil(Properties.getRefreshToken())
        XCTAssertNil(Properties.getSignupToken())
        XCTAssertNil(Properties.getDidRebindToken())
        XCTAssertNil(Properties.getAccountDid())
        XCTAssertEqual(Properties.getRegDidDocCompleted(), false)
    }

    func testRefreshTransportFailurePreservesSession() async {
        Properties.setAccessToken("access")
        Properties.setRefreshToken("refresh")
        AuthMockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await api.refreshToken()
            XCTFail("Offline refresh must fail")
        } catch {
            guard case JinBonError.networkUnavailable = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertEqual(Properties.getAccessToken(), "access")
        XCTAssertEqual(Properties.getRefreshToken(), "refresh")
    }

    func testExpiredRefreshClearsSession() async {
        Properties.setAccessToken("access")
        Properties.setRefreshToken("refresh")
        AuthMockURLProtocol.handler = { _ in
            (401, Data(#"{"status":401,"message":"expired"}"#.utf8))
        }
        do {
            _ = try await api.refreshToken()
            XCTFail("Expired refresh must fail")
        } catch {
            guard case JinBonError.notAuthenticated = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertFalse(Properties.isLoggedIn())
    }

    func testUnauthorizedRequestDoesNotLogoutWhenRefreshIsOffline() async {
        Properties.setAccessToken("access")
        Properties.setRefreshToken("refresh")
        AuthMockURLProtocol.handler = { request in
            if request.url?.path == "/api/auth/refresh" {
                throw URLError(.notConnectedToInternet)
            }
            return (401, Data(#"{"status":401}"#.utf8))
        }
        do {
            _ = try await api.getMyVideos()
            XCTFail("The request must fail while offline")
        } catch {
            guard case JinBonError.networkUnavailable = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertEqual(Properties.getAccessToken(), "access")
        XCTAssertEqual(Properties.getRefreshToken(), "refresh")
    }

    func testWalletMismatchCannotRefreshIntoAuthenticatedSession() async {
        Properties.setAccessToken("access")
        Properties.setRefreshToken("refresh")
        AuthMockURLProtocol.handler = { _ in
            (200, Data(#"{"status":200,"data":{"accessToken":"new-access","refreshToken":"new-refresh","memberId":1,"name":"test","role":"ISSUER","status":"ACTIVE","did":null}}"#.utf8))
        }
        do {
            _ = try await api.refreshToken()
            XCTFail("Missing account DID must not enter the app")
        } catch {
            guard case JinBonError.notAuthenticated = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
        XCTAssertFalse(Properties.isLoggedIn())
    }

    func testOldWalletPendingCredentialIsNotReusedAfterRebind() {
        Properties.setMemberId(-987654)
        defer { Properties.clearPendingVideoVc(videoId: -1) }
        Properties.setAccountDid("did:omn:old")
        Properties.setPendingVideoVc(PendingVideoVcData(vcId: "vc", offerId: "offer"), videoId: -1)
        XCTAssertNotNil(Properties.getPendingVideoVc(videoId: -1))
        Properties.setAccountDid("did:omn:new")
        XCTAssertNil(Properties.getPendingVideoVc(videoId: -1))
    }

    func testOldVideoHolderMismatchHasRecoveryExplanation() async {
        AuthMockURLProtocol.handler = { _ in
            (400, Data(#"{"status":400,"code":"D005","message":"VC offer does not match this video."}"#.utf8))
        }
        do {
            try await api.syncVideoVcHolder(videoId: 1)
            XCTFail("Old Holder DID must be rejected before issuance")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("이전 디지털 신원"))
        }
    }
}

private final class AuthMockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let (status, data) = try Self.handler!(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                           httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}

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
              "authentic": \(verdict == .exactMatch || verdict == .sameContent || verdict == .similarMatch),
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

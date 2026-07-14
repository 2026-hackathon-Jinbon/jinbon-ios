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



import DIDWalletSDK


class IssueVcProtocol : CommonProtocol {
    private let stateLock = NSLock()
    private var issuanceInProgress = false
    
    public static let shared: IssueVcProtocol = {
        let instance = IssueVcProtocol()

        return instance
    }()
    
    @discardableResult
    private func proposeIssueVc(vcPlanId: String, issuer: String, offerId: String? = nil) async throws -> _ProposeIssueVc
    {
        
        let parameter = ProposeIssueVc(id: SDKUtils.generateMessageID(),
                                       vcPlanId: vcPlanId,
                                       issuer: issuer,
                                       offerId: offerId)
        
        let urlString = URLs.TAS_URL+"/tas/api/v1/propose-issue-vc"
        
        let response : _ProposeIssueVc = try await CommunicationClient.sendRequest(urlString: urlString,
                                                                                   requestJsonable: parameter)
        super.txId = response.txId
        self.refId = response.refId

        return response
    }
    
    
    private func requestIssueProfile() async throws
    {
        let parameter = RequestIssueProfile(id: SDKUtils.generateMessageID(),
                                            txId: txId,
                                            serverToken: hServerToken)
        let urlString = URLs.TAS_URL + "/tas/api/v1/request-issue-profile"
        
        self.issueProfile = try await CommunicationClient.sendRequest(urlString: urlString,
                                                                      requestJsonable: parameter)
        super.txId = issueProfile!.txId
    }
   
    @discardableResult
    private func requestIssueVc(passcode: String? = nil) async throws -> String {
        
        let didAuth = try WalletAPI.shared.getSignedDidAuth(authNonce: issueProfile!.authNonce, passcode: passcode)
        
        var vcId: String? = nil
        var issueVc: _RequestIssueVc? = nil
        
        (vcId, issueVc) = try await WalletAPI.shared.requestIssueVc(tasURL: URLs.TAS_URL + "/tas/api/v1/request-issue-vc",
                                                                       hWalletToken: self.hWalletToken,
                                                                       didAuth: didAuth,
                                                                       issuerProfile: issueProfile!,
                                                                       refId: refId,
                                                                       serverToken: hServerToken,
                                                                       APIGatewayURL: URLs.API_URL)
        super.txId = issueVc!.txId
        
        return vcId!
    }
    
    @discardableResult
    private func confirmIssueVc(vcId: String) async throws -> _ConfirmIssueVc {
        
        let parameter = ConfirmIssueVc(id: SDKUtils.generateMessageID(),
                                       txId: super.txId,
                                       serverToken: hServerToken,
                                       vcId: vcId)
                
        let urlString = URLs.TAS_URL + "/tas/api/v1/confirm-issue-vc"
        
        let response : _ConfirmIssueVc = try await CommunicationClient.sendRequest(urlString: urlString,
                                                                                   requestJsonable: parameter)
        super.txId = response.txId
        
        
        return response
    }
    
    public func process(passcode: String? = nil) async throws -> String {
        defer { finishIssuance() }
        let vcId = try await requestIssueVc(passcode: passcode)
        _ = try await confirmIssueVc(vcId: vcId)
        return vcId
    }
    
    public func preProcess(vcPlanId: String, issuer: String, offerId: String? = nil) async throws /*-> (String, String, String, _M210_RequestIssueProfile)*/ {
        try beginIssuance()
        do {
            self.reset()
            try await proposeIssueVc(vcPlanId: vcPlanId, issuer: issuer, offerId: offerId)
            let ecdh = try await super.requestEcdh(type: .HolderDidDocumnet)
            let attestedAppInfo: AttestedAppInfo = try await super.requestAttestedAppInfo()
            try await requestWalletTokenData(purpose: WalletTokenPurposeEnum.ISSUE_VC)
            try await requestCreateToken(attestedAppInfo: attestedAppInfo, ecdh: ecdh, purpose: WalletTokenPurposeEnum.ISSUE_VC)
            try await requestIssueProfile()
        } catch {
            finishIssuance()
            throw error
        }
    }

    public func cancelIssuance() {
        finishIssuance()
        reset()
    }

    private func beginIssuance() throws {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard !issuanceInProgress else {
            throw NSError(
                domain: "JinBon.IssueVc",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "다른 인증서 발급이 진행 중입니다."])
        }
        issuanceInProgress = true
    }

    private func finishIssuance() {
        stateLock.lock()
        issuanceInProgress = false
        stateLock.unlock()
    }
}

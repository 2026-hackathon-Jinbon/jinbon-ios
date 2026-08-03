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

// MARK: - 공통 응답

struct JinBonResponse<T: Codable>: Codable {
    let status: Int
    let message: String?
    let code: String?
    let data: T?
}

// MARK: - 인증 응답

struct AuthTokenData: Codable {
    let accessToken: String
    let refreshToken: String
    let memberId: Int
    let name: String
    let role: String
    let status: String
    let did: String?
    let didRebindToken: String?
}

struct SignupIdentityData: Codable {
    let signupToken: String
    let memberId: Int
    let name: String
    let status: String
}

struct PageData<T: Codable>: Codable {
    let content: [T]
    let totalElements: Int
    let totalPages: Int
    let number: Int
    let last: Bool
}

// MARK: - 영상 상세 (목록 아이템)

struct VideoDetailData: Codable {
    let videoId: Int
    let title: String
    let merkleRoot: String?
    let txHash: String?
    let blockNumber: String?
    let vcId: String?
    let vcIssuanceStatus: String?
    let active: Bool?
    let registeredAt: String?
    let deactivatedAt: String?
}

// MARK: - 영상 등록 응답

struct VideoRegisterData: Codable {
    let videoId: Int?
    let title: String?
    let merkleRoot: String?
    let txHash: String?
    let blockNumber: String?
    let vcId: String?
    let registeredAt: String?
    let alreadyRegistered: Bool?
    let vcPlanId: String?
    let vcIssuerDid: String?
    let vcOfferId: String?
}

/// Wallet에는 VC가 저장됐지만 백엔드 완료 요청이 끝나지 않은 발급 문맥.
/// vcId와 offerId를 함께 보존해야 앱 재실행 후에도 동일한 발급 세션을 복구할 수 있다.
public struct PendingVideoVcData: Codable, Equatable {
    public let vcId: String
    public let offerId: String

    public init(vcId: String, offerId: String) {
        self.vcId = vcId
        self.offerId = offerId
    }
}

// MARK: - 영상 검증 응답

enum VideoVerificationVerdict: String, Codable, CaseIterable {
    case exactMatch = "EXACT_MATCH"
    case sameContent = "SAME_CONTENT"
    case similarMatch = "SIMILAR_MATCH"
    case registeredButRevoked = "REGISTERED_BUT_REVOKED"
    case notRegistered = "NOT_REGISTERED"
    case verificationUnavailable = "VERIFICATION_UNAVAILABLE"

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = VideoVerificationVerdict(rawValue: value) ?? .verificationUnavailable
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct VideoVerifyData: Codable {
    let verdict: VideoVerificationVerdict?
    let similarityDistance: Double?
    let authentic: Bool
    let videoId: Int?
    let issuerDid: String?
    let registeredAt: String?
    let blockchainVerified: Bool
    let vcVerified: Bool
    let active: Bool
    let message: String?
    let notice: String?

    /// verdict 도입 전 백엔드 응답도 안전하게 표시하기 위한 호환 판정.
    var effectiveVerdict: VideoVerificationVerdict {
        if let verdict {
            return verdict
        }
        if !active, videoId != nil {
            return .registeredButRevoked
        }
        return authentic ? .exactMatch : .notRegistered
    }
}

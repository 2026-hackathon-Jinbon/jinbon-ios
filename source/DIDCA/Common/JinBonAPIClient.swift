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

class JinBonAPIClient {

    static let shared = JinBonAPIClient()
    private let baseURL = URLs.JINBON_URL
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    private init() {}

    // MARK: - 내 영상 목록

    func getMyVideos() async throws -> [VideoDetailData] {
        let data = try await request(
            path: "/api/videos",
            method: "GET",
            authenticated: true,
            responseType: PageData<VideoDetailData>.self
        )
        return data?.content ?? []
    }

    func deactivateVideo(videoId: Int) async throws {
        _ = try await request(
            path: "/api/videos/\(videoId)/deactivate",
            method: "PATCH",
            authenticated: true,
            responseType: String.self
        )
    }

    func completeVideoVc(videoId: Int, vcId: String, offerId: String) async throws {
        _ = try await request(
            path: "/api/videos/\(videoId)/vc/complete",
            method: "POST",
            body: ["vcId": vcId, "offerId": offerId],
            authenticated: true,
            responseType: String.self
        )
    }

    func prepareVideoVc(videoId: Int) async throws -> VideoRegisterData {
        guard let data = try await request(
            path: "/api/videos/\(videoId)/vc/prepare",
            method: "POST",
            authenticated: true,
            responseType: VideoRegisterData.self
        ) else {
            throw JinBonError.serverError("인증서 발급을 준비하지 못했습니다.")
        }
        return data
    }

    func syncVideoVcHolder(videoId: Int) async throws {
        _ = try await request(
            path: "/api/videos/\(videoId)/vc/holder",
            method: "PUT",
            authenticated: true,
            responseType: String.self
        )
    }

    func completeSignup(signupToken: String, did: String) async throws -> AuthTokenData {
        let body = ["signupToken": signupToken, "did": did]
        guard let data = try await request(path: "/api/signup/did/complete", method: "POST",
                                           body: body, authenticated: false,
                                           responseType: AuthTokenData.self) else {
            throw JinBonError.serverError("회원가입 완료 처리에 실패했습니다.")
        }
        saveSession(data)
        return data
    }

    func rebindDid(didRebindToken: String, did: String) async throws -> AuthTokenData {
        let body = ["didRebindToken": didRebindToken, "did": did]
        guard let data = try await request(path: "/api/auth/did/rebind", method: "POST",
                                           body: body, authenticated: false,
                                           responseType: AuthTokenData.self) else {
            throw JinBonError.serverError("디지털 신원 재연결에 실패했습니다.")
        }
        saveSession(data)
        return data
    }

    func verifyVideo(url: String) async throws -> VideoVerifyData {
        guard let data = try await request(path: "/api/verify/url", method: "POST",
                                           body: ["url": url], authenticated: false,
                                           responseType: VideoVerifyData.self) else {
            throw JinBonError.serverError("영상 검증에 실패했습니다.")
        }
        return data
    }

    func saveSession(_ data: AuthTokenData) {
        Properties.setAccessToken(data.accessToken)
        Properties.setRefreshToken(data.refreshToken)
        Properties.setMemberId(data.memberId)
        Properties.setMemberName(data.name)
        Properties.setMemberRole(data.role)
    }

    // MARK: - 영상 등록 (multipart)

    func uploadVideo(fileURL: URL, title: String) async throws -> VideoRegisterData {
        let responseData = try await uploadMultipart(
            path: "/api/videos", fileURL: fileURL, title: title, authenticated: true)

        let result = try decoder.decode(JinBonResponse<VideoRegisterData>.self, from: responseData)
        guard result.status == 200, let data = result.data else {
            throw JinBonError.serverError(result.message ?? "Upload failed")
        }
        return data
    }

    // MARK: - 영상 검증 (파일)

    func verifyVideo(fileURL: URL) async throws -> VideoVerifyData {
        let responseData = try await uploadMultipart(
            path: "/api/verify", fileURL: fileURL, title: nil, authenticated: false)

        let result = try decoder.decode(JinBonResponse<VideoVerifyData>.self, from: responseData)
        guard result.status == 200, let data = result.data else {
            throw JinBonError.serverError(result.message ?? "Verification failed")
        }
        return data
    }

    // MARK: - 토큰 갱신

    func refreshToken() async throws -> AuthTokenData {
        guard let refreshToken = Properties.getRefreshToken() else {
            throw JinBonError.notAuthenticated
        }

        let body = ["refreshToken": refreshToken]
        let data = try await request(
            path: "/api/auth/refresh",
            method: "POST",
            body: body,
            authenticated: false,
            responseType: AuthTokenData.self
        )

        guard let tokenData = data else {
            throw JinBonError.serverError("Token refresh failed")
        }

        Properties.setAccessToken(tokenData.accessToken)
        Properties.setRefreshToken(tokenData.refreshToken)
        return tokenData
    }

    // MARK: - 로그아웃

    func logout() async {
        if let refreshToken = Properties.getRefreshToken() {
            let body = ["refreshToken": refreshToken]
            try? await request(
                path: "/api/auth/logout",
                method: "POST",
                body: body,
                authenticated: false,
                responseType: String.self
            )
        }
        Properties.clearAuth()
    }

    func clearLocalSession() {
        Properties.clearAuth()
        Properties.clearDidRebindToken()
    }

    // MARK: - Private

    private func request<T: Codable>(
        path: String,
        method: String,
        body: Encodable? = nil,
        authenticated: Bool = false,
        responseType: T.Type,
        isRetry: Bool = false
    ) async throws -> T? {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw JinBonError.invalidRequest
        }
        var request = URLRequest(url: url)
        request.httpMethod = method

        if authenticated, let token = Properties.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw mapTransportError(error)
        }
        if let http = response as? HTTPURLResponse,
           http.statusCode == 401, authenticated, !isRetry {
            do {
                _ = try await refreshToken()
                return try await self.request(
                    path: path, method: method, body: body,
                    authenticated: true, responseType: responseType,
                    isRetry: true
                )
            } catch {
                Properties.clearAuth()
                throw JinBonError.notAuthenticated
            }
        }
        try checkHTTPResponse(response, data: data)

        let result = try decoder.decode(JinBonResponse<T>.self, from: data)

        if result.status == 401 {
            Properties.clearAuth()
            throw JinBonError.notAuthenticated
        }

        guard result.status == 200 else {
            throw JinBonError.serverError(result.message ?? "Request failed")
        }
        return result.data
    }

    private func uploadMultipart(
        path: String,
        fileURL: URL,
        title: String?,
        authenticated: Bool,
        isRetry: Bool = false
    ) async throws -> Data {
        let boundary = UUID().uuidString
        let multipartURL = try makeMultipartFile(
            sourceURL: fileURL, title: title, boundary: boundary)
        defer { try? FileManager.default.removeItem(at: multipartURL) }

        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw JinBonError.invalidRequest
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if authenticated, let token = Properties.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.upload(for: request, fromFile: multipartURL)
        } catch {
            throw mapTransportError(error)
        }
        if let http = response as? HTTPURLResponse,
           http.statusCode == 401, authenticated, !isRetry {
            do {
                _ = try await refreshToken()
                return try await uploadMultipart(
                    path: path, fileURL: fileURL, title: title,
                    authenticated: true, isRetry: true)
            } catch {
                Properties.clearAuth()
                throw JinBonError.notAuthenticated
            }
        }
        try checkHTTPResponse(response, data: data)
        return data
    }

    private func makeMultipartFile(sourceURL: URL, title: String?, boundary: String) throws -> URL {
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("jinbon-multipart-\(UUID().uuidString)")
        FileManager.default.createFile(atPath: destination.path, contents: nil)

        let output = try FileHandle(forWritingTo: destination)
        do {
            if let title {
                try output.write(contentsOf: Data(
                    "--\(boundary)\r\nContent-Disposition: form-data; name=\"title\"\r\n\r\n\(title)\r\n".utf8))
            }

            let safeFilename = sourceURL.lastPathComponent
                .replacingOccurrences(of: "\"", with: "_")
                .replacingOccurrences(of: "\r", with: "_")
                .replacingOccurrences(of: "\n", with: "_")
            try output.write(contentsOf: Data(
                "--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\(safeFilename)\"\r\nContent-Type: \(mimeTypeFor(safeFilename))\r\n\r\n".utf8))

            let input = try FileHandle(forReadingFrom: sourceURL)
            defer { try? input.close() }
            while let chunk = try input.read(upToCount: 1_048_576), !chunk.isEmpty {
                try output.write(contentsOf: chunk)
            }
            try output.write(contentsOf: Data("\r\n--\(boundary)--\r\n".utf8))
            try output.close()
            return destination
        } catch {
            try? output.close()
            try? FileManager.default.removeItem(at: destination)
            throw error
        }
    }

    private func checkHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw JinBonError.invalidResponse
        }
        guard !(200..<300).contains(http.statusCode) else { return }

        if let payload = try? decoder.decode(APIErrorPayload.self, from: data),
           let message = payload.message, !message.isEmpty {
            throw JinBonError.serverError(message)
        }
        throw JinBonError.httpError(http.statusCode)
    }

    private func mapTransportError(_ error: Error) -> JinBonError {
        guard let urlError = error as? URLError else {
            return .serverError(error.localizedDescription)
        }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost,
             .cannotFindHost, .dnsLookupFailed:
            return .networkUnavailable
        case .timedOut:
            return .timedOut
        default:
            return .serverError(urlError.localizedDescription)
        }
    }

    private func mimeTypeFor(_ filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "avi": return "video/x-msvideo"
        case "mkv": return "video/x-matroska"
        default: return "application/octet-stream"
        }
    }
}

// MARK: - Error

enum JinBonError: LocalizedError {
    case serverError(String)
    case httpError(Int)
    case notAuthenticated
    case networkUnavailable
    case timedOut
    case invalidRequest
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .serverError(let msg): return msg
        case .httpError(let code):
            switch code {
            case 400: return "요청 정보를 확인해주세요."
            case 403: return "이 작업을 수행할 권한이 없습니다."
            case 404: return "요청한 정보를 찾을 수 없습니다."
            case 409: return "이미 처리된 요청이거나 현재 상태와 맞지 않습니다."
            case 413: return "파일 용량이 너무 큽니다."
            case 500...599: return "서버 처리 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요."
            default: return "요청을 완료하지 못했습니다. (\(code))"
            }
        case .notAuthenticated: return "로그인이 만료되었습니다. 다시 로그인해주세요."
        case .networkUnavailable: return "네트워크 연결을 확인한 후 다시 시도해주세요."
        case .timedOut: return "응답 시간이 오래 걸리고 있습니다. 잠시 후 다시 시도해주세요."
        case .invalidRequest: return "서버 주소 설정을 확인해주세요."
        case .invalidResponse: return "서버 응답을 확인할 수 없습니다."
        }
    }
}

private struct APIErrorPayload: Decodable {
    let status: Int?
    let message: String?
    let code: String?
}

// MARK: - AnyEncodable

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ value: Encodable) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

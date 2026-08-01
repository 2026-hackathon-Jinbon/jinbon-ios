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

import Foundation

struct URLs {

    // 개발 환경 기본값 — xcconfig 연결 시 Info.plist 값이 우선 적용됨
    private static let defaults: [String: String] = [
        "TAS_URL":      "http://192.168.219.101:8090",
        "VERIFIER_URL": "http://192.168.219.101:8092",
        "CAS_URL":      "http://192.168.219.101:8094",
        "WALLET_URL":   "http://192.168.219.101:8095",
        "API_URL":      "http://192.168.219.101:8093",
        "DEMO_URL":     "http://192.168.219.101:8099",
        "JINBON_URL":   "http://192.168.219.101:8080",
    ]

    private static func resolve(_ key: String) -> String {
        if let value = Bundle.main.infoDictionary?[key] as? String, !value.isEmpty {
            return value
        }
        return defaults[key]!
    }

    public static var TAS_URL: String      { resolve("TAS_URL") }
    public static var VERIFIER_URL: String  { resolve("VERIFIER_URL") }
    public static var CAS_URL: String      { resolve("CAS_URL") }
    public static var WALLET_URL: String   { resolve("WALLET_URL") }
    public static var API_URL: String      { resolve("API_URL") }
    public static var DEMO_URL: String     { resolve("DEMO_URL") }
    public static var JINBON_URL: String   { resolve("JINBON_URL") }

    public static let JINBON_VC_SCHEMA_ID: String = "jinbon-video-schema-01"
}

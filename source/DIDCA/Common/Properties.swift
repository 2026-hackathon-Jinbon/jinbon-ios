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

#if swift(>=5.8)
@_documentation(visibility: private)
#endif
public class Properties {
    /// set PushToken
    /// - Parameter token: push token
    public static func setPushToken(token: String) {
        UserDefaults.standard.setValue(token, forKey: "push_token")
    }

    /// get getPushToken
    /// - Returns: push token
    public static func getPushToken() -> String? {
        let result: String? = UserDefaults.standard.string(forKey: "push_token")
        return result
    }
    
    /// set UserName
    /// - Parameter id: userName
    public static func setUserName(name: String) {
        UserDefaults.standard.setValue(name, forKey: "user_name")
    }
    
    /// get UserName
    /// - Returns: userName
    public static func getUserName() -> String? {
        let result: String? = UserDefaults.standard.string(forKey: "user_name")
        return result
    }
    
    /// get UserId
    /// - Returns: userId
    public static func getUserId() -> String? {
        let result: String? = UserDefaults.standard.string(forKey: "user_id")
        return result
    }
    
    /// set UserId
    /// - Parameter id: userId
    public static func setUserId(id: String) {
        UserDefaults.standard.setValue(id, forKey: "user_id")
    }
    
    

    public static func getRegDidDocCompleted() -> Bool? {
        let result: Bool? = UserDefaults.standard.bool(forKey: "reg_diddoc_completed")
        return result
    }
    

    public static func setRegDidDocCompleted(status: Bool?) {
        UserDefaults.standard.setValue(status, forKey: "reg_diddoc_completed")
    }
    

    public static func getSubmitCompleted() -> Bool? {
        let result: Bool? = UserDefaults.standard.bool(forKey: "submit_completed")
        return result
    }
    

    public static func setSubmitCompleted(status: Bool?) -> Void {
        UserDefaults.standard.setValue(status, forKey: "submit_completed")
    }
    

    public static func getTasUrl() -> String? {
        let result: String? = UserDefaults.standard.string(forKey: "tas_url")
        return result
    }
    

    public static func setTasUrl(status: String?) -> Void {
        UserDefaults.standard.setValue(status, forKey: "tas_url")
    }
    

    public static func getVerifierUrl() -> String? {
        let result: String? = UserDefaults.standard.string(forKey: "verifier_url")
        return result
    }
    

    public static func setVerifierUrl(status: String?) -> Void {
        UserDefaults.standard.setValue(status, forKey: "verifier_url")
    }
    

    public static func getCaAppId() -> String? {
        
        let result: String? = UserDefaults.standard.string(forKey: "caAppId")
        return result
    }
    

    public static func generateCaAppId() -> Void {
        
        if getCaAppId() != nil { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMM"
        let prefix = formatter.string(from: Date())
        
        let characters = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var randomString = ""
        
        for _ in 0..<11 {
            let index = Int.random(in: 0..<characters.count)
            let randomChar = characters[characters.index(characters.startIndex, offsetBy: index)]
            randomString.append(randomChar)
        }
        
        let caAppId = prefix + randomString
        print("caAppId: \(caAppId)")
        
        UserDefaults.standard.setValue(caAppId, forKey: "caAppId")
    }

    // MARK: - JinBon JWT (Keychain)

    public static func setAccessToken(_ token: String) {
        KeychainHelper.save(key: "jinbon_access_token", value: token)
    }

    public static func getAccessToken() -> String? {
        return KeychainHelper.load(key: "jinbon_access_token")
    }

    public static func setRefreshToken(_ token: String) {
        KeychainHelper.save(key: "jinbon_refresh_token", value: token)
    }

    public static func getRefreshToken() -> String? {
        return KeychainHelper.load(key: "jinbon_refresh_token")
    }

    public static func setMemberId(_ id: Int) {
        UserDefaults.standard.setValue(id, forKey: "jinbon_member_id")
    }

    public static func getMemberId() -> Int? {
        let val = UserDefaults.standard.object(forKey: "jinbon_member_id") as? Int
        return val
    }

    public static func setMemberName(_ name: String) {
        UserDefaults.standard.setValue(name, forKey: "jinbon_member_name")
    }

    public static func setMemberRole(_ role: String) {
        UserDefaults.standard.set(role, forKey: "jinbon_member_role")
    }

    public static func getMemberRole() -> String? {
        UserDefaults.standard.string(forKey: "jinbon_member_role")
    }

    public static func getMemberName() -> String? {
        return UserDefaults.standard.string(forKey: "jinbon_member_name")
    }

    public static func isLoggedIn() -> Bool {
        return getAccessToken() != nil
    }

    public static func clearAuth() {
        KeychainHelper.delete(key: "jinbon_access_token")
        KeychainHelper.delete(key: "jinbon_refresh_token")
        let defaultsKeys = ["jinbon_member_id", "jinbon_member_name", "jinbon_member_role"]
        defaultsKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    public static func setSignupToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "jinbon_signup_token")
    }

    public static func getSignupToken() -> String? {
        UserDefaults.standard.string(forKey: "jinbon_signup_token")
    }

    public static func clearSignupToken() {
        UserDefaults.standard.removeObject(forKey: "jinbon_signup_token")
    }

    public static func setDidRebindToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "jinbon_did_rebind_token")
    }

    public static func getDidRebindToken() -> String? {
        UserDefaults.standard.string(forKey: "jinbon_did_rebind_token")
    }

    public static func clearDidRebindToken() {
        UserDefaults.standard.removeObject(forKey: "jinbon_did_rebind_token")
    }
}

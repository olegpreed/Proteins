//
//  CredentialsStore.swift
//  Proteins
//
//  Created by Oleg on 8/19/25.
//

import Foundation
import Security

final class CredentialsStore {
    static let shared = CredentialsStore()
    private init() {}
    
    func storeCredentials(email: String, password: String) {
        let credentials: [String: Any] = ["email": email, "password": password]
        if let data = try? JSONSerialization.data(withJSONObject: credentials) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: "FirebaseCredentials",
                kSecValueData as String: data
            ]
            SecItemDelete(query as CFDictionary) // avoid duplicates
            SecItemAdd(query as CFDictionary, nil)
        }
    }

    func loadCredentials() -> (email: String, password: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "FirebaseCredentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data,
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String],
           let email = dict["email"], let password = dict["password"] {
            return (email, password)
        }
        return nil
    }
}

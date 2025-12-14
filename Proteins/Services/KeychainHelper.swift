import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    private let service = "com.yourapp.pincode"
    private let account = "userPIN"

    // Save PIN to Keychain
    func savePIN(_ pin: String) -> Bool {
        guard let data = pin.data(using: .utf8) else { return false }

        // Delete any existing PIN first
        deletePIN()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // Retrieve PIN from Keychain
    func getPIN() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let pin = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return pin
    }

    // Delete PIN from Keychain
    func deletePIN() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        SecItemDelete(query as CFDictionary)
    }

    // Check if PIN exists
    func hasPIN() -> Bool {
        getPIN() != nil
    }
}

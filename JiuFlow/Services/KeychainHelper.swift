import Foundation
import Security

enum KeychainHelper {
    private static let service = "com.jiuflow.app"

    static func save(_ key: String, data: Data) {
        // Delete existing
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let status = SecItemAdd(attributes as CFDictionary, nil)

        // Also save to UserDefaults as fallback (for debug reinstalls)
        UserDefaults.standard.set(data, forKey: "kc_\(key)")

        if status != errSecSuccess {
            print("[Keychain] save failed for \(key): \(status)")
        }
    }

    static func save(_ key: String, string: String) {
        if let data = string.data(using: .utf8) { save(key, data: data) }
    }

    static func load(_ key: String) -> Data? {
        // Try Keychain first
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return data
        }

        // Fallback to UserDefaults (survives debug reinstall)
        if let data = UserDefaults.standard.data(forKey: "kc_\(key)") {
            // Re-save to Keychain for next time
            save(key, data: data)
            return data
        }

        return nil
    }

    static func loadString(_ key: String) -> String? {
        guard let data = load(key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        UserDefaults.standard.removeObject(forKey: "kc_\(key)")
    }
}

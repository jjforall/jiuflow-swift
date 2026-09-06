import Foundation
import Security

enum KeychainHelper {
    private static let service = "com.jiuflow.app"
    /// Explicit access group matching the entitlements keychain-access-groups.
    /// Using the team prefix ensures items persist across app reinstalls.
    private static let accessGroup = "5BV85JW8US.com.jiuflow.app"

    static func save(_ key: String, data: Data) {
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: accessGroup,
        ]
        // Delete any existing item first
        SecItemDelete(baseQuery as CFDictionary)

        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status != errSecSuccess {
            print("[KeychainHelper] save failed for \(key): \(status)")
        }

        // Also migrate any old items stored without access group
        migrateOldItem(key)
    }

    static func save(_ key: String, string: String) {
        if let data = string.data(using: .utf8) { save(key, data: data) }
    }

    static func load(_ key: String) -> Data? {
        // 1. Try Keychain with explicit access group
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return data
        }

        // 2. Try loading from old Keychain (no access group — pre-migration)
        if let data = loadOldItem(key) {
            // Re-save to the new access-group Keychain so future reads hit path 1
            save(key, data: data)
            return data
        }

        // 3. Try UserDefaults (legacy fallback, removed on next save)
        if let data = UserDefaults.standard.data(forKey: "kc_\(key)") {
            save(key, data: data)
            UserDefaults.standard.removeObject(forKey: "kc_\(key)")
            return data
        }

        return nil
    }

    static func loadString(_ key: String) -> String? {
        guard let data = load(key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        // Delete from new access-group Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: accessGroup,
        ]
        SecItemDelete(query as CFDictionary)

        // Also delete old items without access group
        let oldQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(oldQuery as CFDictionary)

        // Clean up legacy UserDefaults
        UserDefaults.standard.removeObject(forKey: "kc_\(key)")
    }

    // MARK: - Migration from old Keychain entries (no access group)

    /// Read an item saved by the previous KeychainHelper (no kSecAttrAccessGroup).
    private static func loadOldItem(_ key: String) -> Data? {
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
        return nil
    }

    /// Delete old Keychain item that was stored without access group.
    private static func migrateOldItem(_ key: String) {
        let oldQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        // This will delete the old item (without access group).
        // The new item (with access group) was already saved by the caller.
        SecItemDelete(oldQuery as CFDictionary)
    }
}

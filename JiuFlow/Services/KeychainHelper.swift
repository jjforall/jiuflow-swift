import Foundation
import Security

enum KeychainHelper {
    private static let service = "com.jiuflow.app"

    // Shared file storage that survives app reinstall
    private static var sharedDir: URL? {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?
            .deletingLastPathComponent()
            .appendingPathComponent("tmp/jiuflow_auth")
    }

    static func save(_ key: String, data: Data) {
        // 1. Keychain
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemAdd(attributes as CFDictionary, nil)

        // 2. UserDefaults fallback
        UserDefaults.standard.set(data, forKey: "kc_\(key)")

        // 3. Shared file fallback (survives reinstall)
        saveToFile(key, data: data)
    }

    static func save(_ key: String, string: String) {
        if let data = string.data(using: .utf8) { save(key, data: data) }
    }

    static func load(_ key: String) -> Data? {
        // 1. Try Keychain
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

        // 2. Try UserDefaults
        if let data = UserDefaults.standard.data(forKey: "kc_\(key)") {
            save(key, data: data) // re-save to Keychain
            return data
        }

        // 3. Try shared file
        if let data = loadFromFile(key) {
            save(key, data: data) // re-save to Keychain + UserDefaults
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
        deleteFile(key)
    }

    // MARK: - File-based persistence

    private static func saveToFile(_ key: String, data: Data) {
        guard let dir = sharedDir else { return }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: dir.appendingPathComponent(key))
    }

    private static func loadFromFile(_ key: String) -> Data? {
        guard let dir = sharedDir else { return nil }
        return try? Data(contentsOf: dir.appendingPathComponent(key))
    }

    private static func deleteFile(_ key: String) {
        guard let dir = sharedDir else { return }
        try? FileManager.default.removeItem(at: dir.appendingPathComponent(key))
    }
}

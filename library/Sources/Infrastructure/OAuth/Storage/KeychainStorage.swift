import Foundation
import Security

// Import GitHub types for token storage
#if canImport(Infrastructure)
// Types are in same module
#endif

/// Secure token storage using macOS Keychain
public struct KeychainStorage: Sendable {
    private let service = "ai-prd-generator"

    public init() {}

    /// Store GitHub token in Keychain
    public func store(_ token: GitHubToken, for account: String) throws {
        let data = try JSONEncoder().encode(token)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        // Delete existing first
        SecItemDelete(query as CFDictionary)

        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw GitHubOAuthError.keychainError("Failed to store token: \(status)")
        }
    }

    /// Retrieve GitHub token from Keychain
    public func retrieve(for account: String) throws -> GitHubToken? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            if status == errSecItemNotFound {
                return nil
            }
            throw GitHubOAuthError.keychainError("Failed to retrieve token: \(status)")
        }

        return try JSONDecoder().decode(GitHubToken.self, from: data)
    }

    /// Delete token from Keychain
    public func delete(for account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw GitHubOAuthError.keychainError("Failed to delete token: \(status)")
        }
    }
}

import Foundation

/// Port for cryptographic hashing operations
/// Abstracts hashing to keep Domain layer pure (no CryptoKit dependency)
public protocol HashingPort: Sendable {
    /// Calculate SHA-256 hash of a string
    /// - Parameter content: String to hash
    /// - Returns: Hex-encoded hash string
    func sha256(of content: String) -> String

    /// Calculate SHA-256 hash of data
    /// - Parameter data: Data to hash
    /// - Returns: Hex-encoded hash string
    func sha256(of data: Data) -> String

    /// Verify hash matches content
    /// - Parameters:
    ///   - hash: Expected hash
    ///   - content: Content to verify
    /// - Returns: True if hash matches
    func verify(hash: String, matches content: String) -> Bool
}

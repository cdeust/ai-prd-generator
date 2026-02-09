import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

// Conditional import for cross-platform compatibility
#if canImport(CryptoKit)
import CryptoKit
#else
@preconcurrency import Crypto  // swift-crypto for Linux
#endif

/// CryptoKit implementation of hashing port
/// Infrastructure adapter that provides cryptographic hashing
/// Uses CryptoKit on Apple platforms, Crypto (swift-crypto) on Linux
public struct CryptoKitHashingAdapter: HashingPort {
    public init() {}

    public func sha256(of content: String) -> String {
        guard let data = content.data(using: .utf8) else {
            return ""
        }
        return sha256(of: data)
    }

    public func sha256(of data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    public func verify(hash: String, matches content: String) -> Bool {
        return sha256(of: content) == hash
    }
}

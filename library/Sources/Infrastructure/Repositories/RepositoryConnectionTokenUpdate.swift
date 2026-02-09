import AIPRDSharedUtilities
import Foundation

/// Encodable struct for token update operations
/// Used for repository connection token updates
struct RepositoryConnectionTokenUpdate: Encodable {
    let accessTokenEncrypted: String
    let refreshTokenEncrypted: String?
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case accessTokenEncrypted = "access_token_encrypted"
        case refreshTokenEncrypted = "refresh_token_encrypted"
        case expiresAt = "expires_at"
    }
}

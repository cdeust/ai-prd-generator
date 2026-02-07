import AIPRDSharedUtilities
import Foundation

/// Encodable row for database insert operations
/// Used by repository connection repository for insert operations
struct RepositoryConnectionRow: Encodable {
    let id: String
    let userId: String
    let provider: String
    let accessTokenEncrypted: String
    let refreshTokenEncrypted: String?
    let scopes: [String]
    let providerUserId: String
    let providerUsername: String
    let connectedAt: Date
    let expiresAt: Date?
    let lastSyncedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case provider
        case accessTokenEncrypted = "access_token_encrypted"
        case refreshTokenEncrypted = "refresh_token_encrypted"
        case scopes
        case providerUserId = "provider_user_id"
        case providerUsername = "provider_username"
        case connectedAt = "connected_at"
        case expiresAt = "expires_at"
        case lastSyncedAt = "last_synced_at"
    }
}

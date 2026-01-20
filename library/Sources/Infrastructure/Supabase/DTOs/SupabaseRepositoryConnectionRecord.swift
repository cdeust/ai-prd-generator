import Foundation

/// Supabase Repository Connection Record
/// Maps to repository_connections table schema (000_complete_schema.sql)
/// Stores OAuth connections to GitHub/Bitbucket for repository integration
public struct SupabaseRepositoryConnectionRecord: Codable, Sendable {
    let id: String
    let userId: String
    let provider: String
    let accessTokenEncrypted: String
    let refreshTokenEncrypted: String?
    let scopes: [String]
    let providerUserId: String
    let providerUsername: String
    let connectedAt: String
    let expiresAt: String?
    let lastSyncedAt: String?
    let createdAt: String
    let updatedAt: String

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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        provider = try container.decode(String.self, forKey: .provider)
        accessTokenEncrypted = try container.decode(String.self, forKey: .accessTokenEncrypted)
        refreshTokenEncrypted = try container.decodeIfPresent(String.self, forKey: .refreshTokenEncrypted)
        providerUserId = try container.decode(String.self, forKey: .providerUserId)
        providerUsername = try container.decode(String.self, forKey: .providerUsername)
        connectedAt = try container.decode(String.self, forKey: .connectedAt)
        expiresAt = try container.decodeIfPresent(String.self, forKey: .expiresAt)
        lastSyncedAt = try container.decodeIfPresent(String.self, forKey: .lastSyncedAt)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)

        // Handle both JSON string and array for scopes
        if let jsonString = try? container.decode(String.self, forKey: .scopes) {
            if let data = jsonString.data(using: .utf8),
               let array = try? JSONDecoder().decode([String].self, from: data) {
                scopes = array
            } else {
                scopes = []
            }
        } else if let array = try? container.decode([String].self, forKey: .scopes) {
            scopes = array
        } else {
            scopes = []
        }
    }

    /// Initializer for creating records to insert
    public init(
        id: String,
        userId: String,
        provider: String,
        accessTokenEncrypted: String,
        refreshTokenEncrypted: String? = nil,
        scopes: [String],
        providerUserId: String,
        providerUsername: String,
        connectedAt: String,
        expiresAt: String? = nil,
        lastSyncedAt: String? = nil,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.userId = userId
        self.provider = provider
        self.accessTokenEncrypted = accessTokenEncrypted
        self.refreshTokenEncrypted = refreshTokenEncrypted
        self.scopes = scopes
        self.providerUserId = providerUserId
        self.providerUsername = providerUsername
        self.connectedAt = connectedAt
        self.expiresAt = expiresAt
        self.lastSyncedAt = lastSyncedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

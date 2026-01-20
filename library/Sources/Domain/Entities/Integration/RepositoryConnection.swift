import Foundation

/// Repository connection entity
/// Represents OAuth connection to GitHub/Bitbucket
public struct RepositoryConnection: Identifiable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let provider: RepositoryProvider
    public let accessToken: String
    public let refreshToken: String?
    public let scopes: [String]
    public let providerUserId: String
    public let providerUsername: String
    public let connectedAt: Date
    public let expiresAt: Date?
    public let lastSyncedAt: Date?

    public init(
        id: UUID = UUID(),
        userId: UUID,
        provider: RepositoryProvider,
        accessToken: String,
        refreshToken: String? = nil,
        scopes: [String],
        providerUserId: String,
        providerUsername: String,
        connectedAt: Date = Date(),
        expiresAt: Date? = nil,
        lastSyncedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.provider = provider
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.scopes = scopes
        self.providerUserId = providerUserId
        self.providerUsername = providerUsername
        self.connectedAt = connectedAt
        self.expiresAt = expiresAt
        self.lastSyncedAt = lastSyncedAt
    }

    /// Check if token is expired
    public var isExpired: Bool {
        guard let expiresAt = expiresAt else {
            return false
        }
        return Date() >= expiresAt
    }
}

import Foundation

/// Repository connection port
/// Defines interface for OAuth connection persistence
public protocol RepositoryConnectionPort: Sendable {
    /// Save new repository connection
    func saveConnection(_ connection: RepositoryConnection) async throws -> RepositoryConnection

    /// Find connection by ID
    func findConnection(id: UUID) async throws -> RepositoryConnection?

    /// Find connections for user
    func findConnections(
        userId: UUID,
        provider: RepositoryProvider?
    ) async throws -> [RepositoryConnection]

    /// Find connection by provider user ID
    func findConnectionByProviderUserId(
        providerUserId: String,
        provider: RepositoryProvider
    ) async throws -> RepositoryConnection?

    /// Delete connection
    func deleteConnection(id: UUID) async throws

    /// Update last sync timestamp
    func updateLastSync(connectionId: UUID, date: Date) async throws

    /// Update access token
    func updateToken(
        connectionId: UUID,
        accessToken: String,
        refreshToken: String?,
        expiresAt: Date?
    ) async throws

    /// Update user ID for connection (used when OAuth creates placeholder then finds real user)
    func updateUserId(connectionId: UUID, userId: UUID) async throws
}

import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Helper for refreshing OAuth connection tokens
enum ConnectionTokenRefresher {
    /// Refresh an expired connection token
    static func refresh(
        connection: RepositoryConnection,
        clientId: String,
        clientSecret: String,
        oauthClient: OAuthClientPort,
        connectionRepository: RepositoryConnectionPort
    ) async throws -> RepositoryConnection {
        guard let refreshToken = connection.refreshToken else {
            throw OAuthError.tokenExpired
        }

        let tokenResponse = try await oauthClient.refreshToken(
            provider: connection.provider,
            refreshToken: refreshToken,
            clientId: clientId,
            clientSecret: clientSecret
        )

        try await connectionRepository.updateToken(
            connectionId: connection.id,
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expiresAt: tokenResponse.expiresAt
        )

        return RepositoryConnection(
            id: connection.id,
            userId: connection.userId,
            provider: connection.provider,
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken ?? connection.refreshToken,
            scopes: connection.scopes,
            providerUserId: connection.providerUserId,
            providerUsername: connection.providerUsername,
            connectedAt: connection.connectedAt,
            expiresAt: tokenResponse.expiresAt,
            lastSyncedAt: connection.lastSyncedAt
        )
    }
}

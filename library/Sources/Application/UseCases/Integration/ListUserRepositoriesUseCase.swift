import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Use case for listing repositories from connected provider
/// Fetches accessible repositories for authenticated user
public struct ListUserRepositoriesUseCase: Sendable {
    private let connectionRepository: RepositoryConnectionPort
    private let repositoryFetcher: RepositoryFetcherPort
    private let oauthClient: OAuthClientPort

    public init(
        connectionRepository: RepositoryConnectionPort,
        repositoryFetcher: RepositoryFetcherPort,
        oauthClient: OAuthClientPort
    ) {
        self.connectionRepository = connectionRepository
        self.repositoryFetcher = repositoryFetcher
        self.oauthClient = oauthClient
    }

    public func execute(
        connectionId: UUID,
        clientId: String,
        clientSecret: String
    ) async throws -> [RemoteRepository] {
        guard var connection = try await connectionRepository.findConnection(id: connectionId) else {
            throw OAuthError.invalidConnection
        }

        if connection.isExpired, connection.refreshToken != nil {
            connection = try await refreshConnectionToken(
                connection: connection,
                clientId: clientId,
                clientSecret: clientSecret
            )
        }

        return try await repositoryFetcher.listRepositories(connection: connection)
    }

    private func refreshConnectionToken(
        connection: RepositoryConnection,
        clientId: String,
        clientSecret: String
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

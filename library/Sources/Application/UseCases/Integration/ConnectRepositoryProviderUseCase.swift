import Foundation
import Domain

/// Use case for connecting a repository provider via OAuth
/// Handles OAuth callback and stores connection
public struct ConnectRepositoryProviderUseCase: Sendable {
    private let connectionRepository: RepositoryConnectionPort
    private let oauthClient: OAuthClientPort
    private let repositoryFetcher: RepositoryFetcherPort

    public init(
        connectionRepository: RepositoryConnectionPort,
        oauthClient: OAuthClientPort,
        repositoryFetcher: RepositoryFetcherPort
    ) {
        self.connectionRepository = connectionRepository
        self.oauthClient = oauthClient
        self.repositoryFetcher = repositoryFetcher
    }

    public func execute(
        userId: UUID,
        provider: RepositoryProvider,
        authorizationCode: String,
        redirectURI: String,
        clientId: String,
        clientSecret: String
    ) async throws -> RepositoryConnection {
        let tokenResponse = try await oauthClient.exchangeCodeForToken(
            provider: provider,
            code: authorizationCode,
            redirectURI: redirectURI,
            clientId: clientId,
            clientSecret: clientSecret
        )

        let tempConnection = RepositoryConnection(
            userId: userId,
            provider: provider,
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            scopes: tokenResponse.scopes,
            providerUserId: "",
            providerUsername: "",
            expiresAt: tokenResponse.expiresAt
        )

        let userInfo = try await repositoryFetcher.getUserInfo(
            connection: tempConnection
        )

        let connection = RepositoryConnection(
            userId: userId,
            provider: provider,
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            scopes: tokenResponse.scopes,
            providerUserId: userInfo.id,
            providerUsername: userInfo.username,
            expiresAt: tokenResponse.expiresAt
        )

        return try await connectionRepository.saveConnection(connection)
    }
}

import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

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
        let tokenResponse = try await exchangeAuthorizationCode(
            provider: provider,
            authorizationCode: authorizationCode,
            redirectURI: redirectURI,
            clientId: clientId,
            clientSecret: clientSecret
        )

        let tempConnection = createTemporaryConnection(
            userId: userId,
            provider: provider,
            tokenResponse: tokenResponse
        )

        let userInfo = try await repositoryFetcher.getUserInfo(connection: tempConnection)

        return try await saveConnection(
            tempConnection: tempConnection,
            userInfo: userInfo
        )
    }

    private func exchangeAuthorizationCode(
        provider: RepositoryProvider,
        authorizationCode: String,
        redirectURI: String,
        clientId: String,
        clientSecret: String
    ) async throws -> OAuthTokenResponse {
        try await oauthClient.exchangeCodeForToken(
            provider: provider,
            code: authorizationCode,
            redirectURI: redirectURI,
            clientId: clientId,
            clientSecret: clientSecret
        )
    }

    private func createTemporaryConnection(
        userId: UUID,
        provider: RepositoryProvider,
        tokenResponse: OAuthTokenResponse
    ) -> RepositoryConnection {
        RepositoryConnection(
            userId: userId,
            provider: provider,
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            scopes: tokenResponse.scopes,
            providerUserId: "",
            providerUsername: "",
            expiresAt: tokenResponse.expiresAt
        )
    }

    private func saveConnection(
        tempConnection: RepositoryConnection,
        userInfo: ProviderUserInfo
    ) async throws -> RepositoryConnection {
        let connection = RepositoryConnection(
            userId: tempConnection.userId,
            provider: tempConnection.provider,
            accessToken: tempConnection.accessToken,
            refreshToken: tempConnection.refreshToken,
            scopes: tempConnection.scopes,
            providerUserId: userInfo.id,
            providerUsername: userInfo.username,
            expiresAt: tempConnection.expiresAt
        )
        return try await connectionRepository.saveConnection(connection)
    }
}

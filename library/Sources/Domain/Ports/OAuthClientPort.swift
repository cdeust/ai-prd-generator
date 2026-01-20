import Foundation

/// OAuth client port
/// Defines interface for OAuth 2.0 authorization flow
public protocol OAuthClientPort: Sendable {
    /// Get authorization URL for OAuth flow
    func getAuthorizationURL(
        provider: RepositoryProvider,
        redirectURI: String,
        state: String,
        scopes: [String]?,
        clientId: String
    ) -> URL

    /// Exchange authorization code for access token
    func exchangeCodeForToken(
        provider: RepositoryProvider,
        code: String,
        redirectURI: String,
        clientId: String,
        clientSecret: String
    ) async throws -> OAuthTokenResponse

    /// Refresh access token
    func refreshToken(
        provider: RepositoryProvider,
        refreshToken: String,
        clientId: String,
        clientSecret: String
    ) async throws -> OAuthTokenResponse
}

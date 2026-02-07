import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Standard OAuth 2.0 client implementation
/// Implements OAuth Authorization Code Flow
public final class StandardOAuthClient: OAuthClientPort, Sendable {
    private let httpClient: HTTPClient

    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    public func getAuthorizationURL(
        provider: RepositoryProvider,
        redirectURI: String,
        state: String,
        scopes: [String]?,
        clientId: String
    ) -> URL {
        var components = URLComponents(string: provider.authorizationURL)!
        let scopeString = (scopes ?? provider.requiredScopes).joined(separator: " ")

        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopeString),
            URLQueryItem(name: "state", value: state)
        ]

        return components.url!
    }

    public func exchangeCodeForToken(
        provider: RepositoryProvider,
        code: String,
        redirectURI: String,
        clientId: String,
        clientSecret: String
    ) async throws -> OAuthTokenResponse {
        let url = URL(string: provider.tokenURL)!

        // GitHub requires form-urlencoded, not JSON
        let bodyString = [
            "grant_type=authorization_code",
            "code=\(code)",
            "redirect_uri=\(redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectURI)",
            "client_id=\(clientId)",
            "client_secret=\(clientSecret)"
        ].joined(separator: "&")

        let bodyData = bodyString.data(using: .utf8)!

        let request = HTTPRequest(
            url: url,
            method: .post,
            headers: [
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded"
            ],
            body: bodyData
        )

        let response = try await httpClient.execute(request)

        guard response.statusCode == 200 else {
            let errorMessage = String(data: response.data, encoding: .utf8) ?? "Unknown error"
            throw OAuthError.providerError(errorMessage)
        }

        return try parseTokenResponse(response.data)
    }

    public func refreshToken(
        provider: RepositoryProvider,
        refreshToken: String,
        clientId: String,
        clientSecret: String
    ) async throws -> OAuthTokenResponse {
        let url = URL(string: provider.tokenURL)!

        // OAuth requires form-urlencoded
        let bodyString = [
            "grant_type=refresh_token",
            "refresh_token=\(refreshToken)",
            "client_id=\(clientId)",
            "client_secret=\(clientSecret)"
        ].joined(separator: "&")

        let bodyData = bodyString.data(using: .utf8)!

        let request = HTTPRequest(
            url: url,
            method: .post,
            headers: [
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded"
            ],
            body: bodyData
        )

        let response = try await httpClient.execute(request)

        guard response.statusCode == 200 else {
            throw OAuthError.invalidRefreshToken
        }

        return try parseTokenResponse(response.data)
    }

    private func parseTokenResponse(_ data: Data) throws -> OAuthTokenResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw OAuthError.providerError("Invalid token response")
        }

        let tokenType = json["token_type"] as? String ?? "bearer"
        let scope = json["scope"] as? String
        let refreshToken = json["refresh_token"] as? String
        let expiresIn = json["expires_in"] as? Int

        return OAuthTokenResponse(
            accessToken: accessToken,
            tokenType: tokenType,
            scope: scope,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }
}

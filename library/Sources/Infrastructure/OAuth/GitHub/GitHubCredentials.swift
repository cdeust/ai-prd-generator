import Foundation

/// GitHub OAuth application credentials
public struct GitHubCredentials: Sendable {
    public let clientId: String
    public let clientSecret: String

    public init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
}

/// Stored GitHub access token
public struct GitHubToken: Codable, Sendable {
    public let accessToken: String
    public let tokenType: String
    public let scope: String
    public let createdAt: Date

    public init(accessToken: String, tokenType: String = "Bearer", scope: String = "", createdAt: Date = Date()) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.scope = scope
        self.createdAt = createdAt
    }
}

/// GitHub user information
public struct GitHubUserInfo: Sendable {
    public let id: String
    public let login: String
    public let email: String?
    public let name: String?

    public init(id: String, login: String, email: String?, name: String?) {
        self.id = id
        self.login = login
        self.email = email
        self.name = name
    }
}

/// OAuth errors
public enum GitHubOAuthError: Error {
    case noAccessToken
    case invalidCredentials
    case authorizationFailed
    case networkError(Error)
    case keychainError(String)
    case deviceFlowExpired
    case userDenied
}

import Foundation

/// GitHub OAuth authentication errors
public enum GitHubOAuthError: Error, Sendable {
    case noAccessToken
    case invalidCredentials
    case authorizationFailed
    case networkError(Error)
    case keychainError(String)
    case deviceFlowExpired
    case userDenied
}

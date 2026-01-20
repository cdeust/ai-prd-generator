import Foundation

/// OAuth error enumeration
/// Defines errors that can occur during OAuth flow
public enum OAuthError: Error, Sendable {
    case invalidAuthorizationCode
    case tokenExpired
    case invalidRefreshToken
    case missingScopes([String])
    case providerError(String)
    case invalidConnection
    case configurationMissing(String)
    case invalidState
    case accessDenied

    public var localizedDescription: String {
        switch self {
        case .invalidAuthorizationCode:
            return "Invalid authorization code"
        case .tokenExpired:
            return "OAuth token has expired"
        case .invalidRefreshToken:
            return "Invalid refresh token"
        case .missingScopes(let scopes):
            return "Missing required scopes: \(scopes.joined(separator: ", "))"
        case .providerError(let message):
            return "Provider error: \(message)"
        case .invalidConnection:
            return "Invalid or expired connection"
        case .configurationMissing(let key):
            return "Missing OAuth configuration: \(key)"
        case .invalidState:
            return "Invalid state parameter"
        case .accessDenied:
            return "User denied access"
        }
    }
}

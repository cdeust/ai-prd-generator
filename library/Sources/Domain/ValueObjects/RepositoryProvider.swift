import Foundation

/// Repository provider enumeration
/// Defines supported OAuth providers for repository integration
public enum RepositoryProvider: String, Sendable, Codable {
    case github
    case bitbucket

    /// Authorization URL for OAuth flow
    public var authorizationURL: String {
        switch self {
        case .github:
            return "https://github.com/login/oauth/authorize"
        case .bitbucket:
            return "https://bitbucket.org/site/oauth2/authorize"
        }
    }

    /// Token exchange URL
    public var tokenURL: String {
        switch self {
        case .github:
            return "https://github.com/login/oauth/access_token"
        case .bitbucket:
            return "https://bitbucket.org/site/oauth2/access_token"
        }
    }

    /// Required OAuth scopes
    public var requiredScopes: [String] {
        switch self {
        case .github:
            return ["repo"]
        case .bitbucket:
            return ["repository"]
        }
    }

    /// API base URL
    public var apiBaseURL: String {
        switch self {
        case .github:
            return "https://api.github.com"
        case .bitbucket:
            return "https://api.bitbucket.org/2.0"
        }
    }
}

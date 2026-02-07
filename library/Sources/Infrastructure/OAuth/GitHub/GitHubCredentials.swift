import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// GitHub OAuth application credentials
public struct GitHubCredentials: Sendable {
    public let clientId: String
    public let clientSecret: String

    public init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
}

// GitHubToken, GitHubUserInfo, and GitHubOAuthError moved to Domain layer
// Import them from Domain to maintain backward compatibility

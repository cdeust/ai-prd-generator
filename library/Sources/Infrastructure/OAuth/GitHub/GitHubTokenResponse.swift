import AIPRDSharedUtilities
import Foundation

/// GitHub OAuth token response
public struct GitHubTokenResponse: Codable {
    public let access_token: String?
    public let token_type: String?
    public let scope: String?

    public init(access_token: String?, token_type: String?, scope: String?) {
        self.access_token = access_token
        self.token_type = token_type
        self.scope = scope
    }
}

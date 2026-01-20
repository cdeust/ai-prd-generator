import Foundation

/// GitHub access token for authenticated API requests
public struct GitHubToken: Codable, Sendable {
    public let accessToken: String
    public let tokenType: String
    public let scope: String
    public let createdAt: Date

    public init(
        accessToken: String,
        tokenType: String = "Bearer",
        scope: String = "",
        createdAt: Date = Date()
    ) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.scope = scope
        self.createdAt = createdAt
    }
}

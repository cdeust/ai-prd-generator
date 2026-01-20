import Foundation

/// OAuth token response entity
/// Represents OAuth token response from provider
public struct OAuthTokenResponse: Sendable {
    public let accessToken: String
    public let tokenType: String
    public let scope: String?
    public let refreshToken: String?
    public let expiresIn: Int?

    public init(
        accessToken: String,
        tokenType: String = "bearer",
        scope: String? = nil,
        refreshToken: String? = nil,
        expiresIn: Int? = nil
    ) {
        self.accessToken = accessToken
        self.tokenType = tokenType
        self.scope = scope
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }

    /// Calculate expiration date
    public var expiresAt: Date? {
        guard let expiresIn = expiresIn else { return nil }
        return Date().addingTimeInterval(TimeInterval(expiresIn))
    }

    /// Parse scopes from scope string
    public var scopes: [String] {
        guard let scope = scope else { return [] }
        return scope.split(separator: " ").map(String.init)
    }
}

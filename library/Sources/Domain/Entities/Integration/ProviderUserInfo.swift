import Foundation

/// Provider user info
/// Represents user information from OAuth provider
public struct ProviderUserInfo: Sendable {
    public let id: String
    public let username: String
    public let email: String?
    public let name: String?

    public init(
        id: String,
        username: String,
        email: String? = nil,
        name: String? = nil
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.name = name
    }
}

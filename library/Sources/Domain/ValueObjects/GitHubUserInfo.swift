import Foundation

/// GitHub user account information
public struct GitHubUserInfo: Sendable {
    public let id: String
    public let login: String
    public let email: String?
    public let name: String?

    public init(
        id: String,
        login: String,
        email: String?,
        name: String?
    ) {
        self.id = id
        self.login = login
        self.email = email
        self.name = name
    }
}

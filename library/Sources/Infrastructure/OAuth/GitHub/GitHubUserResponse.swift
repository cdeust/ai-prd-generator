import AIPRDSharedUtilities
import Foundation

/// GitHub user information API response
public struct GitHubUserResponse: Codable {
    public let id: Int
    public let login: String
    public let email: String?
    public let name: String?
    public let avatar_url: String?

    public init(id: Int, login: String, email: String?, name: String?, avatar_url: String?) {
        self.id = id
        self.login = login
        self.email = email
        self.name = name
        self.avatar_url = avatar_url
    }
}

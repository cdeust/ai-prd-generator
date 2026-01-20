import Foundation

/// GitHub repository information
public struct GitHubRepository: Codable, Sendable {
    public let id: Int
    public let name: String
    public let fullName: String
    public let description: String?
    public let isPrivate: Bool
    public let defaultBranch: String
    public let language: String?

    public init(
        id: Int,
        name: String,
        fullName: String,
        description: String?,
        isPrivate: Bool,
        defaultBranch: String,
        language: String?
    ) {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.description = description
        self.isPrivate = isPrivate
        self.defaultBranch = defaultBranch
        self.language = language
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case description
        case isPrivate = "private"
        case defaultBranch = "default_branch"
        case language
    }
}

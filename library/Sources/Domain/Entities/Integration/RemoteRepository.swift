import Foundation

/// Remote repository entity
/// Represents a repository from GitHub/Bitbucket
public struct RemoteRepository: Identifiable, Sendable {
    public let id: String
    public let provider: RepositoryProvider
    public let name: String
    public let fullName: String
    public let url: String
    public let cloneUrl: String
    public let isPrivate: Bool
    public let defaultBranch: String
    public let language: String?
    public let description: String?
    public let stars: Int?
    public let updatedAt: Date

    public init(
        id: String,
        provider: RepositoryProvider,
        name: String,
        fullName: String,
        url: String,
        cloneUrl: String,
        isPrivate: Bool,
        defaultBranch: String,
        language: String? = nil,
        description: String? = nil,
        stars: Int? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.provider = provider
        self.name = name
        self.fullName = fullName
        self.url = url
        self.cloneUrl = cloneUrl
        self.isPrivate = isPrivate
        self.defaultBranch = defaultBranch
        self.language = language
        self.description = description
        self.stars = stars
        self.updatedAt = updatedAt
    }

    /// Parse owner and repo name from fullName
    public var owner: String {
        let components = fullName.split(separator: "/")
        return components.first.map(String.init) ?? ""
    }

    /// Parse repo name from fullName
    public var repoName: String {
        let components = fullName.split(separator: "/")
        return components.last.map(String.init) ?? name
    }
}

import Foundation

/// Public request to index a codebase
/// Public DTO for codebase indexing requests
public struct IndexCodebaseRequest: Sendable {
    public let repositoryUrl: String
    public let branch: String
    public let repositoryType: String

    public init(
        repositoryUrl: String,
        branch: String = "main",
        repositoryType: String = "github"
    ) {
        self.repositoryUrl = repositoryUrl
        self.branch = branch
        self.repositoryType = repositoryType
    }
}

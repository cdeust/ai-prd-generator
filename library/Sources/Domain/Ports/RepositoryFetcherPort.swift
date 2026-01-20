import Foundation

/// Repository fetcher port
/// Defines interface for fetching repositories from external providers
public protocol RepositoryFetcherPort: Sendable {
    /// List repositories accessible to authenticated user
    func listRepositories(
        connection: RepositoryConnection
    ) async throws -> [RemoteRepository]

    /// Fetch file tree for repository at specific branch
    func fetchFileTree(
        repository: RemoteRepository,
        branch: String,
        connection: RepositoryConnection
    ) async throws -> [FileTreeNode]

    /// Fetch file content from repository
    func fetchFileContent(
        repository: RemoteRepository,
        filePath: String,
        branch: String,
        connection: RepositoryConnection
    ) async throws -> String

    /// Get user info from provider
    func getUserInfo(
        connection: RepositoryConnection
    ) async throws -> ProviderUserInfo
}

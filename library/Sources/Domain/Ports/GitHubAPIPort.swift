import Foundation

/// Port for GitHub API operations
/// Provides access to repositories and files
public protocol GitHubAPIPort: Sendable {
    /// Fetch repository information
    func fetchRepository(owner: String, name: String) async throws -> GitHubRepository

    /// Fetch all files from repository recursively
    func fetchAllFiles(
        owner: String,
        repo: String,
        path: String
    ) async throws -> [GitHubFile]
}

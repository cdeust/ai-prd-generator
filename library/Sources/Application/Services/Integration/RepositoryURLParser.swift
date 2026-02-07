import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Helper for parsing repository URLs into RemoteRepository entities
enum RepositoryURLParser {
    /// Parse a repository URL and extract repository information
    static func parse(_ url: String, provider: RepositoryProvider) throws -> RemoteRepository {
        guard let urlComponents = URLComponents(string: url) else {
            throw RepositoryFetchError.invalidURL(url)
        }

        let pathComponents = urlComponents.path.split(separator: "/")
        guard pathComponents.count >= 2 else {
            throw RepositoryFetchError.invalidURL(url)
        }

        let owner = String(pathComponents[pathComponents.count - 2])
        let repoName = String(pathComponents[pathComponents.count - 1])
            .replacingOccurrences(of: ".git", with: "")

        return RemoteRepository(
            id: "\(owner)/\(repoName)",
            provider: provider,
            name: repoName,
            fullName: "\(owner)/\(repoName)",
            url: url,
            cloneUrl: url,
            isPrivate: true,
            defaultBranch: "main"
        )
    }
}

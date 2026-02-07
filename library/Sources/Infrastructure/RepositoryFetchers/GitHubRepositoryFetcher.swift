import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// GitHub repository fetcher implementation
/// Implements RepositoryFetcherPort for GitHub API v3
public final class GitHubRepositoryFetcher: RepositoryFetcherPort, Sendable {
    private let httpClient: HTTPClient
    private let baseURL = "https://api.github.com"

    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    public func listRepositories(
        connection: RepositoryConnection
    ) async throws -> [RemoteRepository] {
        let url = URL(string: "\(baseURL)/user/repos")!

        let request = HTTPRequest(
            url: url,
            method: .get,
            headers: [
                "Accept": "application/vnd.github.v3+json",
                "Authorization": "Bearer \(connection.accessToken)"
            ]
        )

        let response = try await httpClient.execute(request)

        guard response.statusCode == 200 else {
            throw mapHTTPError(response.statusCode, data: response.data)
        }

        guard let repos = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] else {
            throw RepositoryFetchError.parseError("Invalid response format")
        }

        return repos.compactMap { parseRepository($0) }
    }

    public func fetchFileTree(
        repository: RemoteRepository,
        branch: String,
        connection: RepositoryConnection
    ) async throws -> [FileTreeNode] {
        let url = URL(string: "\(baseURL)/repos/\(repository.fullName)/git/trees/\(branch)?recursive=1")!

        let request = HTTPRequest(
            url: url,
            method: .get,
            headers: [
                "Accept": "application/vnd.github.v3+json",
                "Authorization": "Bearer \(connection.accessToken)"
            ]
        )

        let response = try await httpClient.execute(request)

        guard response.statusCode == 200 else {
            throw mapHTTPError(response.statusCode, data: response.data)
        }

        guard let json = try JSONSerialization.jsonObject(with: response.data) as? [String: Any],
              let tree = json["tree"] as? [[String: Any]] else {
            throw RepositoryFetchError.parseError("Invalid tree response")
        }

        return tree.compactMap { parseTreeNode($0) }
    }

    public func fetchFileContent(
        repository: RemoteRepository,
        filePath: String,
        branch: String,
        connection: RepositoryConnection
    ) async throws -> String {
        let encodedPath = filePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? filePath
        let url = URL(string: "\(baseURL)/repos/\(repository.fullName)/contents/\(encodedPath)?ref=\(branch)")!

        let request = HTTPRequest(
            url: url,
            method: .get,
            headers: [
                "Accept": "application/vnd.github.v3+json",
                "Authorization": "Bearer \(connection.accessToken)"
            ]
        )

        let response = try await httpClient.execute(request)

        guard response.statusCode == 200 else {
            if response.statusCode == 404 {
                throw RepositoryFetchError.fileNotFound(filePath)
            }
            throw mapHTTPError(response.statusCode, data: response.data)
        }

        guard let json = try JSONSerialization.jsonObject(with: response.data) as? [String: Any],
              let content = json["content"] as? String,
              let encoding = json["encoding"] as? String,
              encoding == "base64" else {
            throw RepositoryFetchError.parseError("Invalid content response")
        }

        guard let decodedData = Data(base64Encoded: content.replacingOccurrences(of: "\n", with: "")),
              let decodedString = String(data: decodedData, encoding: .utf8) else {
            throw RepositoryFetchError.parseError("Failed to decode content")
        }

        return decodedString
    }

    public func getUserInfo(
        connection: RepositoryConnection
    ) async throws -> ProviderUserInfo {
        let url = URL(string: "\(baseURL)/user")!

        let request = HTTPRequest(
            url: url,
            method: .get,
            headers: [
                "Accept": "application/vnd.github.v3+json",
                "Authorization": "Bearer \(connection.accessToken)"
            ]
        )

        let response = try await httpClient.execute(request)

        guard response.statusCode == 200 else {
            throw mapHTTPError(response.statusCode, data: response.data)
        }

        guard let json = try JSONSerialization.jsonObject(with: response.data) as? [String: Any],
              let id = json["id"] as? Int,
              let login = json["login"] as? String else {
            throw RepositoryFetchError.parseError("Invalid user info response")
        }

        return ProviderUserInfo(
            id: String(id),
            username: login,
            email: json["email"] as? String,
            name: json["name"] as? String
        )
    }

    private func parseRepository(_ json: [String: Any]) -> RemoteRepository? {
        guard let id = json["id"] as? Int,
              let name = json["name"] as? String,
              let fullName = json["full_name"] as? String,
              let htmlURL = json["html_url"] as? String,
              let cloneURL = json["clone_url"] as? String,
              let isPrivate = json["private"] as? Bool,
              let defaultBranch = json["default_branch"] as? String else {
            return nil
        }

        let updatedAtString = json["updated_at"] as? String
        let updatedAt = updatedAtString.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()

        return RemoteRepository(
            id: String(id),
            provider: .github,
            name: name,
            fullName: fullName,
            url: htmlURL,
            cloneUrl: cloneURL,
            isPrivate: isPrivate,
            defaultBranch: defaultBranch,
            language: json["language"] as? String,
            description: json["description"] as? String,
            stars: json["stargazers_count"] as? Int,
            updatedAt: updatedAt
        )
    }

    private func parseTreeNode(_ json: [String: Any]) -> FileTreeNode? {
        guard let path = json["path"] as? String,
              let typeString = json["type"] as? String else {
            return nil
        }

        let type: FileTreeNodeType = typeString == "blob" ? .file : .directory

        return FileTreeNode(
            path: path,
            type: type,
            size: json["size"] as? Int,
            sha: json["sha"] as? String
        )
    }

    private func mapHTTPError(_ statusCode: Int, data: Data) -> Error {
        switch statusCode {
        case 401, 403:
            return RepositoryFetchError.accessDenied
        case 404:
            return RepositoryFetchError.repositoryNotFound
        case 429:
            return RepositoryFetchError.rateLimitExceeded
        default:
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(statusCode)"
            return RepositoryFetchError.networkError(message)
        }
    }
}

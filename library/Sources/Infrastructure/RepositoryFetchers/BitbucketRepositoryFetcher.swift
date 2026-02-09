import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Bitbucket repository fetcher implementation
/// Implements RepositoryFetcherPort for Bitbucket API 2.0
public final class BitbucketRepositoryFetcher: RepositoryFetcherPort, Sendable {
    private let httpClient: HTTPClient
    private let baseURL = "https://api.bitbucket.org/2.0"

    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    public func listRepositories(
        connection: RepositoryConnection
    ) async throws -> [RemoteRepository] {
        let url = URL(string: "\(baseURL)/repositories/\(connection.providerUsername)")!

        let request = HTTPRequest(
            url: url,
            method: .get,
            headers: [
                "Accept": "application/json",
                "Authorization": "Bearer \(connection.accessToken)"
            ]
        )

        let response = try await httpClient.execute(request)

        guard response.statusCode == 200 else {
            throw mapHTTPError(response.statusCode, data: response.data)
        }

        guard let json = try JSONSerialization.jsonObject(with: response.data) as? [String: Any],
              let values = json["values"] as? [[String: Any]] else {
            throw RepositoryFetchError.parseError("Invalid response format")
        }

        return values.compactMap { parseRepository($0) }
    }

    public func fetchFileTree(
        repository: RemoteRepository,
        branch: String,
        connection: RepositoryConnection
    ) async throws -> [FileTreeNode] {
        let url = URL(string: "\(baseURL)/repositories/\(repository.fullName)/src/\(branch)/?pagelen=100")!

        let request = HTTPRequest(
            url: url,
            method: .get,
            headers: [
                "Accept": "application/json",
                "Authorization": "Bearer \(connection.accessToken)"
            ]
        )

        let response = try await httpClient.execute(request)

        guard response.statusCode == 200 else {
            throw mapHTTPError(response.statusCode, data: response.data)
        }

        guard let json = try JSONSerialization.jsonObject(with: response.data) as? [String: Any],
              let values = json["values"] as? [[String: Any]] else {
            throw RepositoryFetchError.parseError("Invalid tree response")
        }

        return values.compactMap { parseTreeNode($0) }
    }

    public func fetchFileContent(
        repository: RemoteRepository,
        filePath: String,
        branch: String,
        connection: RepositoryConnection
    ) async throws -> String {
        let encodedPath = filePath.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? filePath
        let url = URL(string: "\(baseURL)/repositories/\(repository.fullName)/src/\(branch)/\(encodedPath)")!

        let request = HTTPRequest(
            url: url,
            method: .get,
            headers: [
                "Accept": "text/plain",
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

        guard let content = String(data: response.data, encoding: .utf8) else {
            throw RepositoryFetchError.parseError("Failed to decode content")
        }

        return content
    }

    public func getUserInfo(
        connection: RepositoryConnection
    ) async throws -> ProviderUserInfo {
        let url = URL(string: "\(baseURL)/user")!

        let request = HTTPRequest(
            url: url,
            method: .get,
            headers: [
                "Accept": "application/json",
                "Authorization": "Bearer \(connection.accessToken)"
            ]
        )

        let response = try await httpClient.execute(request)

        guard response.statusCode == 200 else {
            throw mapHTTPError(response.statusCode, data: response.data)
        }

        guard let json = try JSONSerialization.jsonObject(with: response.data) as? [String: Any],
              let uuid = json["uuid"] as? String,
              let username = json["username"] as? String else {
            throw RepositoryFetchError.parseError("Invalid user info response")
        }

        return ProviderUserInfo(
            id: uuid,
            username: username,
            email: json["email"] as? String,
            name: json["display_name"] as? String
        )
    }

    private func parseRepository(_ json: [String: Any]) -> RemoteRepository? {
        guard let uuid = json["uuid"] as? String,
              let name = json["name"] as? String,
              let fullName = json["full_name"] as? String,
              let linksJSON = json["links"] as? [String: Any],
              let htmlJSON = linksJSON["html"] as? [String: Any],
              let htmlURL = htmlJSON["href"] as? String,
              let cloneJSON = linksJSON["clone"] as? [[String: Any]],
              let httpsClone = cloneJSON.first(where: { ($0["name"] as? String) == "https" }),
              let cloneURL = httpsClone["href"] as? String,
              let isPrivate = json["is_private"] as? Bool else {
            return nil
        }

        let mainBranch = (json["mainbranch"] as? [String: Any])?["name"] as? String ?? "main"

        let updatedAtString = json["updated_on"] as? String
        let updatedAt = updatedAtString.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()

        return RemoteRepository(
            id: uuid,
            provider: .bitbucket,
            name: name,
            fullName: fullName,
            url: htmlURL,
            cloneUrl: cloneURL,
            isPrivate: isPrivate,
            defaultBranch: mainBranch,
            language: json["language"] as? String,
            description: json["description"] as? String,
            updatedAt: updatedAt
        )
    }

    private func parseTreeNode(_ json: [String: Any]) -> FileTreeNode? {
        guard let path = json["path"] as? String,
              let typeString = json["type"] as? String else {
            return nil
        }

        let type: FileTreeNodeType = typeString == "commit_file" ? .file : .directory

        return FileTreeNode(
            path: path,
            type: type,
            size: json["size"] as? Int
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

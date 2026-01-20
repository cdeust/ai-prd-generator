import Foundation

/// GitHub API client for fetching repository data
public actor GitHubAPIClient {
    private let token: GitHubToken

    public init(token: GitHubToken) {
        self.token = token
    }

    // MARK: - Repository Operations

    /// Fetch repository information
    public func fetchRepository(owner: String, name: String) async throws -> GitHubRepository {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(name)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubOAuthError.networkError(URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            throw GitHubOAuthError.authorizationFailed
        }

        return try JSONDecoder().decode(GitHubRepository.self, from: data)
    }

    /// Fetch directory contents (files and folders)
    public func fetchContents(owner: String, repo: String, path: String = "") async throws -> [GitHubContent] {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GitHubOAuthError.authorizationFailed
        }

        return try JSONDecoder().decode([GitHubContent].self, from: data)
    }

    /// Recursively fetch all files in repository
    public func fetchAllFiles(owner: String, repo: String, path: String = "") async throws -> [GitHubFile] {
        var files: [GitHubFile] = []
        let contents = try await fetchContents(owner: owner, repo: repo, path: path)

        for content in contents {
            if content.type == "file" {
                files.append(GitHubFile(
                    path: content.path,
                    name: content.name,
                    size: content.size,
                    downloadUrl: content.download_url
                ))
            } else if content.type == "dir" {
                // Recursively fetch subdirectory
                let subfiles = try await fetchAllFiles(owner: owner, repo: repo, path: content.path)
                files.append(contentsOf: subfiles)
            }
        }

        return files
    }

    /// Download file content
    public func downloadFile(url: String) async throws -> String {
        guard let downloadURL = URL(string: url) else {
            throw GitHubOAuthError.networkError(URLError(.badURL))
        }

        var request = URLRequest(url: downloadURL)
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let content = String(data: data, encoding: .utf8) else {
            throw GitHubOAuthError.networkError(URLError(.cannotDecodeContentData))
        }

        return content
    }
}

// MARK: - GitHub Data Models

public struct GitHubRepository: Codable, Sendable {
    public let id: Int
    public let name: String
    public let full_name: String
    public let description: String?
    public let `private`: Bool
    public let default_branch: String
    public let language: String?

    public init(id: Int, name: String, full_name: String, description: String?, `private`: Bool, default_branch: String, language: String?) {
        self.id = id
        self.name = name
        self.full_name = full_name
        self.description = description
        self.`private` = `private`
        self.default_branch = default_branch
        self.language = language
    }
}

public struct GitHubContent: Codable, Sendable {
    public let name: String
    public let path: String
    public let type: String  // "file" or "dir"
    public let size: Int
    public let download_url: String?

    public init(name: String, path: String, type: String, size: Int, download_url: String?) {
        self.name = name
        self.path = path
        self.type = type
        self.size = size
        self.download_url = download_url
    }
}

public struct GitHubFile: Sendable {
    public let path: String
    public let name: String
    public let size: Int
    public let downloadUrl: String?

    public init(path: String, name: String, size: Int, downloadUrl: String?) {
        self.path = path
        self.name = name
        self.size = size
        self.downloadUrl = downloadUrl
    }
}

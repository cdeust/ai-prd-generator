import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// GitHub API client for fetching repository data
public actor GitHubAPIClient: GitHubAPIPort {
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

// GitHubRepository and GitHubFile moved to Domain layer
// GitHubContent is now defined in GitHubContent.swift

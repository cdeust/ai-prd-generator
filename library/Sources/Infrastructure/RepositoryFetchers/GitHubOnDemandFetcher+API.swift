import Foundation
import AIPRDSharedUtilities

/// GitHub API methods for on-demand fetching
extension GitHubOnDemandFetcher {
    func fetchFileTree(
        owner: String,
        repo: String,
        branch: String,
        accessToken: String?
    ) async throws -> [GitHubTreeNodeDTO] {
        let url = buildTreeURL(owner: owner, repo: repo, branch: branch)
        let request = buildRequest(url: url, accessToken: accessToken)
        let response = try await httpClient.execute(request)

        guard response.statusCode == 200 else {
            throw OnDemandFetchError.apiError(response.statusCode)
        }

        return try parseTreeResponse(response.data)
    }

    func fetchFileContent(
        owner: String,
        repo: String,
        path: String,
        branch: String,
        accessToken: String?
    ) async throws -> String {
        let url = buildContentURL(owner: owner, repo: repo, path: path, branch: branch)
        let request = buildRequest(url: url, accessToken: accessToken)
        let response = try await httpClient.execute(request)

        guard response.statusCode == 200 else {
            throw OnDemandFetchError.apiError(response.statusCode)
        }

        return try parseContentResponse(response.data)
    }

    func fetchFileContents(
        files: [GitHubTreeNodeDTO],
        owner: String,
        repo: String,
        branch: String,
        accessToken: String?
    ) async throws -> FetchedFileContents {
        let maxFiles = min(files.count, 10)
        var chunks: [String] = []
        var paths: [String] = []

        for file in files.prefix(maxFiles) {
            if let content = try? await fetchFileContent(
                owner: owner,
                repo: repo,
                path: file.path,
                branch: branch,
                accessToken: accessToken
            ) {
                chunks.append(content)
                paths.append(file.path)
            }
        }

        return FetchedFileContents(chunks: chunks, paths: paths)
    }
}

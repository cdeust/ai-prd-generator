import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// GitHub on-demand fetcher implementation
/// Fetches codebase context directly from GitHub URLs without pre-indexing
public final class GitHubOnDemandFetcher: OnDemandCodebaseFetcherPort, Sendable {
    let httpClient: HTTPClient

    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    public func fetchContext(
        from url: String,
        branch: String?,
        accessToken: String?,
        query: String
    ) async throws -> RAGSearchResults {
        let parsed = try parseGitHubURL(url)
        let branchName = branch ?? "main"

        print("🔍 [OnDemandFetcher] Fetching from \(parsed.owner)/\(parsed.repo) @ \(branchName)")

        let files = try await fetchFileTree(
            owner: parsed.owner,
            repo: parsed.repo,
            branch: branchName,
            accessToken: accessToken
        )

        print("📁 [OnDemandFetcher] Found \(files.count) files in repository")

        let relevantFiles = filterRelevantFiles(files, query: query)
        print("🎯 [OnDemandFetcher] \(relevantFiles.count) files potentially relevant")

        let contents = try await fetchFileContents(
            files: relevantFiles,
            owner: parsed.owner,
            repo: parsed.repo,
            branch: branchName,
            accessToken: accessToken
        )

        print("✅ [OnDemandFetcher] Fetched \(contents.chunks.count) file contents")

        return RAGSearchResults(
            relevantFiles: contents.paths,
            relevantChunks: contents.chunks,
            averageRelevanceScore: 0.7
        )
    }
}

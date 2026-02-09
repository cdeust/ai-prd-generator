import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Service for GitHub repository integration
/// Handles authentication and repository access
public actor GitHubIntegrationService: Sendable {
    private let authClient: GitHubAuthenticationPort
    private let apiClientFactory: (GitHubToken) -> GitHubAPIPort

    public init(
        authClient: GitHubAuthenticationPort,
        apiClientFactory: @escaping (GitHubToken) -> GitHubAPIPort
    ) {
        self.authClient = authClient
        self.apiClientFactory = apiClientFactory
    }

    /// Authenticate with GitHub using GitHub CLI
    /// Runs `gh auth login` interactively
    public func authenticate() async throws -> GitHubToken {
        return try await authClient.authenticate()
    }

    /// Check if already authenticated
    public func isAuthenticated() async throws -> Bool {
        return try await authClient.getStoredToken() != nil
    }

    /// Get stored authentication token
    public func getStoredToken() async throws -> GitHubToken? {
        return try await authClient.getStoredToken()
    }

    /// Revoke authentication
    public func revokeAuthentication() async throws {
        try await authClient.deleteToken()
    }

    /// Fetch repository information
    public func fetchRepository(
        owner: String,
        name: String,
        token: GitHubToken
    ) async throws -> GitHubRepository {
        let apiClient = apiClientFactory(token)
        return try await apiClient.fetchRepository(owner: owner, name: name)
    }

    /// Fetch all files from repository
    public func fetchAllFiles(
        owner: String,
        repo: String,
        token: GitHubToken,
        path: String = ""
    ) async throws -> [GitHubFile] {
        let apiClient = apiClientFactory(token)
        return try await apiClient.fetchAllFiles(
            owner: owner,
            repo: repo,
            path: path
        )
    }
}

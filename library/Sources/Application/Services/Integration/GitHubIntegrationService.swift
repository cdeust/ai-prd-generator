import Foundation
import Domain

/// Service for GitHub repository integration
/// Handles authentication and repository access
public actor GitHubIntegrationService: Sendable {
    private let deviceFlowClient: GitHubDeviceFlowPort
    private let apiClientFactory: (GitHubToken) -> GitHubAPIPort

    public init(
        deviceFlowClient: GitHubDeviceFlowPort,
        apiClientFactory: @escaping (GitHubToken) -> GitHubAPIPort
    ) {
        self.deviceFlowClient = deviceFlowClient
        self.apiClientFactory = apiClientFactory
    }

    /// Authenticate with GitHub using Device Flow
    /// Displays code for user to enter at github.com/login/device
    public func authenticate() async throws -> GitHubToken {
        return try await deviceFlowClient.authenticate()
    }

    /// Check if already authenticated
    public func isAuthenticated() throws -> Bool {
        return try deviceFlowClient.getStoredToken() != nil
    }

    /// Get stored authentication token
    public func getStoredToken() throws -> GitHubToken? {
        return try deviceFlowClient.getStoredToken()
    }

    /// Revoke authentication
    public func revokeAuthentication() throws {
        try deviceFlowClient.deleteToken()
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

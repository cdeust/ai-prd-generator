import Foundation

/// Port for GitHub authentication
/// Abstracts authentication mechanism (GitHub CLI, OAuth, etc.)
public protocol GitHubAuthenticationPort: Sendable {
    /// Authenticate with GitHub
    /// Returns access token after user authorizes
    func authenticate() async throws -> GitHubToken

    /// Get stored token from secure storage
    func getStoredToken() async throws -> GitHubToken?

    /// Delete stored token (revoke authentication)
    func deleteToken() async throws
}

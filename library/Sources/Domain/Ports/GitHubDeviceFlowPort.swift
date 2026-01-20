import Foundation

/// Port for GitHub Device Flow authentication
/// Enables CLI-style authentication without OAuth app setup
public protocol GitHubDeviceFlowPort: Sendable {
    /// Authenticate with GitHub using Device Flow
    /// Returns access token after user authorizes
    func authenticate() async throws -> GitHubToken

    /// Get stored token from secure storage
    func getStoredToken() throws -> GitHubToken?

    /// Delete stored token (revoke authentication)
    func deleteToken() throws
}

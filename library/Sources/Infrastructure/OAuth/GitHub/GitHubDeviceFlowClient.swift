import Foundation
import Domain

/// GitHub Device Flow OAuth client for CLI authentication
/// Uses GitHub's device flow (like GitHub CLI) - no client_secret needed
public actor GitHubDeviceFlowClient: GitHubDeviceFlowPort {
    private let clientId: String
    private let keychainStorage: KeychainStorage

    // Public client ID for AI PRD Generator skill
    // This is NOT a secret - device flow uses public client IDs
    private static let defaultClientId = "Iv23liPRDGenerator" // TODO: Replace with actual registered client_id

    public init(clientId: String? = nil, keychainStorage: KeychainStorage = KeychainStorage()) {
        self.clientId = clientId ?? Self.defaultClientId
        self.keychainStorage = keychainStorage
    }

    // MARK: - Device Flow

    /// Device code response from GitHub
    public struct DeviceCodeResponse: Codable {
        let device_code: String
        let user_code: String
        let verification_uri: String
        let expires_in: Int
        let interval: Int
    }

    /// Request device code from GitHub
    public func requestDeviceCode(scope: String = "repo read:org") async throws -> DeviceCodeResponse {
        let url = URL(string: "https://github.com/login/device/code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_id": clientId,
            "scope": scope
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubOAuthError.networkError(URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            throw GitHubOAuthError.authorizationFailed
        }

        return try JSONDecoder().decode(DeviceCodeResponse.self, from: data)
    }

    /// Poll for access token (call repeatedly until authorized)
    public func pollForAccessToken(deviceCode: String, interval: Int) async throws -> GitHubToken {
        let url = URL(string: "https://github.com/login/oauth/access_token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_id": clientId,
            "device_code": deviceCode,
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code"
        ]
        request.httpBody = try JSONEncoder().encode(body)

        // Poll until authorized (with exponential backoff)
        var pollInterval = TimeInterval(interval)

        while true {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw GitHubOAuthError.networkError(URLError(.badServerResponse))
            }

            if httpResponse.statusCode == 200 {
                // Success - got token
                let tokenResponse = try JSONDecoder().decode(GitHubTokenResponse.self, from: data)

                guard let accessToken = tokenResponse.access_token else {
                    throw GitHubOAuthError.noAccessToken
                }

                let token = GitHubToken(
                    accessToken: accessToken,
                    tokenType: tokenResponse.token_type ?? "Bearer",
                    scope: tokenResponse.scope ?? ""
                )

                // Store token in Keychain
                try keychainStorage.store(token, for: "github")

                return token
            }

            // Check error response
            if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
               let error = errorResponse["error"] {

                switch error {
                case "authorization_pending":
                    // Still waiting for user to authorize - continue polling
                    break

                case "slow_down":
                    // Increase polling interval
                    pollInterval += 5

                case "expired_token":
                    throw GitHubOAuthError.authorizationFailed

                case "access_denied":
                    throw GitHubOAuthError.authorizationFailed

                default:
                    throw GitHubOAuthError.authorizationFailed
                }
            }

            // Wait before next poll
            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
    }

    /// Complete device flow authentication
    public func authenticate() async throws -> GitHubToken {
        // Check if we already have a token
        if let existingToken = try keychainStorage.retrieve(for: "github") {
            // Verify token is still valid
            do {
                _ = try await fetchUserInfo(token: existingToken.accessToken)
                print("✅ Using existing GitHub authentication")
                return existingToken
            } catch {
                // Token invalid, continue with new authentication
                print("⚠️  Existing token invalid, re-authenticating...")
                try? keychainStorage.delete(for: "github")
            }
        }

        print("🔐 GitHub Authentication Required")
        print("")

        // Request device code
        let deviceCode = try await requestDeviceCode()

        print("📝 Please visit: \(deviceCode.verification_uri)")
        print("")
        print("🔑 Enter code: \(deviceCode.user_code)")
        print("")
        print("⏱️  Code expires in \(deviceCode.expires_in / 60) minutes")
        print("")

        // Try to open browser automatically
        if let url = URL(string: deviceCode.verification_uri) {
            let openProcess = Process()
            openProcess.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            openProcess.arguments = [url.absoluteString]
            try? openProcess.run()
            print("🌐 Browser opened - paste code there")
        }

        print("⏳ Waiting for authorization...")

        // Poll for token
        let token = try await pollForAccessToken(
            deviceCode: deviceCode.device_code,
            interval: deviceCode.interval
        )

        // Fetch user info to confirm
        let userInfo = try await fetchUserInfo(token: token.accessToken)
        print("✅ Authenticated as @\(userInfo.login)")

        return token
    }

    /// Fetch GitHub user information using access token
    public func fetchUserInfo(token: String) async throws -> GitHubUserInfo {
        let userURL = URL(string: "https://api.github.com/user")!
        var userRequest = URLRequest(url: userURL)
        userRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        userRequest.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        userRequest.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        let (userData, response) = try await URLSession.shared.data(for: userRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubOAuthError.networkError(URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            throw GitHubOAuthError.authorizationFailed
        }

        let userResponse = try JSONDecoder().decode(GitHubUserResponse.self, from: userData)

        return GitHubUserInfo(
            id: String(userResponse.id),
            login: userResponse.login,
            email: userResponse.email,
            name: userResponse.name
        )
    }

    /// Get stored token from Keychain
    public func getStoredToken() throws -> GitHubToken? {
        try keychainStorage.retrieve(for: "github")
    }

    /// Delete stored token (logout)
    public func deleteToken() throws {
        try keychainStorage.delete(for: "github")
    }
}

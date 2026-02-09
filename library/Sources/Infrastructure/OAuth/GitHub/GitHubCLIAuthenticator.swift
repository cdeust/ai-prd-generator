import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// GitHub authentication using GitHub CLI (gh)
/// Wraps `gh auth login` for user authentication
public actor GitHubCLIAuthenticator: GitHubAuthenticationPort {

    public init() {}

    /// Authenticate with GitHub using gh CLI
    public func authenticate() async throws -> GitHubToken {
        // Check if gh is installed
        let whichProcess = Process()
        whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        whichProcess.arguments = ["gh"]

        let whichPipe = Pipe()
        whichProcess.standardOutput = whichPipe
        try whichProcess.run()
        whichProcess.waitUntilExit()

        guard whichProcess.terminationStatus == 0 else {
            print("❌ GitHub CLI (gh) not found")
            print("📦 Install it with: brew install gh")
            print("Or visit: https://cli.github.com")
            throw GitHubOAuthError.authorizationFailed
        }

        // Check if already authenticated
        let statusProcess = Process()
        statusProcess.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/gh")
        statusProcess.arguments = ["auth", "status"]

        let statusPipe = Pipe()
        statusProcess.standardError = statusPipe
        try statusProcess.run()
        statusProcess.waitUntilExit()

        if statusProcess.terminationStatus == 0 {
            // Already authenticated, get token
            print("✅ Already authenticated with GitHub CLI")
            return try await getStoredToken() ?? {
                throw GitHubOAuthError.noAccessToken
            }()
        }

        // Need to authenticate
        print("🔐 GitHub Authentication Required")
        print("")
        print("Running: gh auth login")
        print("")

        let loginProcess = Process()
        loginProcess.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/gh")
        loginProcess.arguments = ["auth", "login", "--web", "--scopes", "repo,read:org"]

        // Inherit stdin/stdout/stderr so user can interact
        loginProcess.standardInput = FileHandle.standardInput
        loginProcess.standardOutput = FileHandle.standardOutput
        loginProcess.standardError = FileHandle.standardError

        try loginProcess.run()
        loginProcess.waitUntilExit()

        guard loginProcess.terminationStatus == 0 else {
            throw GitHubOAuthError.authorizationFailed
        }

        print("")
        print("✅ Authentication successful")

        return try await getStoredToken() ?? {
            throw GitHubOAuthError.noAccessToken
        }()
    }

    /// Get stored token from gh CLI
    public func getStoredToken() async throws -> GitHubToken? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/gh")
        process.arguments = ["auth", "token"]

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let tokenString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !tokenString.isEmpty else {
            return nil
        }

        return GitHubToken(
            accessToken: tokenString,
            tokenType: "Bearer",
            scope: "repo read:org"
        )
    }

    /// Logout from GitHub CLI
    public func deleteToken() async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/gh")
        process.arguments = ["auth", "logout", "--hostname", "github.com"]

        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw GitHubOAuthError.authorizationFailed
        }
    }
}

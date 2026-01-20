import Foundation

/// Repository fetch error enumeration
/// Defines errors during repository operations
public enum RepositoryFetchError: Error, Sendable {
    case repositoryNotFound
    case accessDenied
    case rateLimitExceeded
    case invalidBranch(String)
    case fileNotFound(String)
    case networkError(String)
    case invalidURL(String)
    case parseError(String)
    case unsupportedProvider(String)

    public var localizedDescription: String {
        switch self {
        case .repositoryNotFound:
            return "Repository not found"
        case .accessDenied:
            return "Access denied to repository"
        case .rateLimitExceeded:
            return "API rate limit exceeded"
        case .invalidBranch(let branch):
            return "Invalid branch: \(branch)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidURL(let url):
            return "Invalid repository URL: \(url)"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .unsupportedProvider(let provider):
            return "Unsupported provider: \(provider)"
        }
    }
}

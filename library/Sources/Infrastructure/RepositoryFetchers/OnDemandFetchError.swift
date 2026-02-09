import Foundation

/// Errors that can occur during on-demand repository fetching
public enum OnDemandFetchError: Error, LocalizedError {
    case invalidURL
    case apiError(Int)
    case parseError
    case decodeError

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid GitHub repository URL"
        case .apiError(let code): return "GitHub API error: \(code)"
        case .parseError: return "Failed to parse GitHub API response"
        case .decodeError: return "Failed to decode file content"
        }
    }
}

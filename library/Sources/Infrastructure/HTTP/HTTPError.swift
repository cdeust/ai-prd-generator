import AIPRDSharedUtilities
import Foundation

/// HTTP Error types
/// Represents all possible HTTP failures
public enum HTTPError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case statusCode(Int)
    case networkError(Error)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid HTTP response"
        case .statusCode(let code):
            return "HTTP error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

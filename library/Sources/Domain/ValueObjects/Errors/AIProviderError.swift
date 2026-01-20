import Foundation

/// AI Provider error types
/// Value object representing all possible AI provider failures
public enum AIProviderError: Error, LocalizedError, Sendable {
    case modelNotAvailable(String)
    case promptTooLong(String)
    case generationFailed(String)
    case invalidConfiguration(String)
    case invalidResponse
    case rateLimited
    case authenticationFailed
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .modelNotAvailable(let message):
            return "Model not available: \(message)"
        case .promptTooLong(let message):
            return "Prompt too long: \(message)"
        case .generationFailed(let message):
            return "Generation failed: \(message)"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .invalidResponse:
            return "Invalid response from AI provider"
        case .rateLimited:
            return "Rate limit exceeded"
        case .authenticationFailed:
            return "Authentication failed"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

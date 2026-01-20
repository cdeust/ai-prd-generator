import Foundation

/// Public library errors
/// Public error types for client applications
public enum AIPRDError: Error, LocalizedError, Sendable {
    case invalidInput(String)
    case generationFailed(String)
    case codebaseNotFound(UUID)
    case indexingFailed(String)
    case notConfigured
    case unauthorized

    public var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .generationFailed(let reason):
            return "PRD generation failed: \(reason)"
        case .codebaseNotFound(let id):
            return "Codebase not found: \(id)"
        case .indexingFailed(let reason):
            return "Indexing failed: \(reason)"
        case .notConfigured:
            return "Library not configured. Please configure with API credentials."
        case .unauthorized:
            return "Unauthorized. Check API credentials."
        }
    }
}

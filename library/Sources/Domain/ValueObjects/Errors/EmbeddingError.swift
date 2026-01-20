import Foundation

/// Embedding generation errors
/// Domain error for embedding operations
public enum EmbeddingError: Error {
    case invalidInput(String)
    case apiError(statusCode: Int, message: String)
    case batchSizeExceeded(max: Int)
    case modelNotAvailable
    case generationFailed
}

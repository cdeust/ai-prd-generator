import Foundation

/// Errors that can occur during tokenization
public enum TokenizationError: Error, Sendable {
    case encodingFailed(reason: String)
    case decodingFailed(reason: String)
    case countingFailed(reason: String)
    case truncationFailed(reason: String)
    case invalidInput(reason: String)
    case providerNotAvailable(TokenizerProvider)
}

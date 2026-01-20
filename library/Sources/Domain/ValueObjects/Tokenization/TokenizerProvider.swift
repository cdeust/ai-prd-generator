import Foundation

/// Provider types for tokenization
public enum TokenizerProvider: String, Sendable, Codable {
    case claude
    case openai
    case apple
    case custom
}

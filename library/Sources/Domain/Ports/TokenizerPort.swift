import Foundation

/// Port for provider-specific token counting and text encoding.
///
/// Different AI providers use different tokenization schemes:
/// - Claude: Uses Anthropic's tokenizer (based on tiktoken)
/// - OpenAI: Uses tiktoken with GPT encoding
/// - Apple Intelligence: Uses Foundation Models tokenizer
///
/// Token counting is critical for:
/// - Budget allocation across models (4K-200K context windows)
/// - Cost estimation
/// - Context window management
/// - Chunking decisions
public protocol TokenizerPort: Sendable {
    /// Count tokens in text without encoding
    ///
    /// - Parameter text: Text to count tokens for
    /// - Returns: Number of tokens
    /// - Throws: TokenizationError if counting fails
    func countTokens(in text: String) async throws -> Int

    /// Encode text into token IDs
    ///
    /// - Parameter text: Text to encode
    /// - Returns: Array of token IDs
    /// - Throws: TokenizationError if encoding fails
    func encode(_ text: String) async throws -> [Int]

    /// Decode token IDs back into text
    ///
    /// - Parameter tokens: Token IDs to decode
    /// - Returns: Decoded text
    /// - Throws: TokenizationError if decoding fails
    func decode(_ tokens: [Int]) async throws -> String

    /// Truncate text to fit within token limit
    ///
    /// - Parameters:
    ///   - text: Text to truncate
    ///   - maxTokens: Maximum number of tokens allowed
    /// - Returns: Truncated text that fits within token limit
    /// - Throws: TokenizationError if truncation fails
    func truncate(_ text: String, to maxTokens: Int) async throws -> String

    /// Provider identifier for this tokenizer
    var provider: TokenizerProvider { get }
}

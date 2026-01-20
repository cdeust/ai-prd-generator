import Foundation
import Domain

/// Claude tokenizer using Anthropic's tokenization scheme.
///
/// Implementation notes:
/// - Claude uses a modified tiktoken tokenizer
/// - Average English: ~4 characters per token
/// - Average code: ~3 characters per token
/// - Context limit: 200,000 tokens (Sonnet 3.5)
///
/// This is a placeholder implementation using character-based estimation.
/// TODO: Integrate actual Anthropic tokenizer when Swift SDK is available.
public actor ClaudeTokenizer: TokenizerPort {
    private let averageCharsPerToken: Double = 4.0

    public init() {}

    public func countTokens(in text: String) async throws -> Int {
        // Character-based estimation until official tokenizer is available
        // Claude: ~4 chars/token for English text
        guard !text.isEmpty else { return 0 }

        let characterCount = text.count
        let estimatedTokens = Int(ceil(Double(characterCount) / averageCharsPerToken))

        return estimatedTokens
    }

    public func encode(_ text: String) async throws -> [Int] {
        // Placeholder: Split into chunks approximating tokens
        // Real implementation would use Anthropic's tokenizer
        guard !text.isEmpty else { return [] }

        let tokenCount = try await countTokens(in: text)
        return Array(0..<tokenCount)
    }

    public func decode(_ tokens: [Int]) async throws -> String {
        // Placeholder: Can't decode without real tokenizer
        throw TokenizationError.decodingFailed(
            reason: "Claude tokenizer decode requires Anthropic SDK"
        )
    }

    public func truncate(
        _ text: String,
        to maxTokens: Int
    ) async throws -> String {
        guard maxTokens > 0 else {
            throw TokenizationError.invalidInput(
                reason: "maxTokens must be positive"
            )
        }

        let currentTokens = try await countTokens(in: text)

        guard currentTokens > maxTokens else {
            return text
        }

        let targetChars = Int(Double(maxTokens) * averageCharsPerToken)
        guard targetChars <= text.count else {
            return text
        }

        return String(text.prefix(targetChars))
    }

    public nonisolated var provider: TokenizerProvider {
        .claude
    }
}

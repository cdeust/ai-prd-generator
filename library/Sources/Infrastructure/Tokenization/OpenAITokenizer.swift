import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// OpenAI tokenizer implementing tiktoken cl100k_base encoding.
///
/// Implementation details:
/// - GPT-4, GPT-4 Turbo, GPT-4o use cl100k_base encoding
/// - ~100,000 tokens in vocabulary
/// - Byte-level BPE with special regex pre-tokenization
/// - Average English: ~4 characters per token
/// - Average code: ~3.5 characters per token
/// - Context limits: GPT-4 Turbo (128K), GPT-4o (128K)
///
/// Token counting methodology:
/// 1. Pre-tokenize using tiktoken cl100k_base regex pattern
/// 2. Apply byte-level BPE estimation
/// 3. Handle special patterns: contractions, numbers, whitespace
///
/// Accuracy: Within 5% of tiktoken for most text.
public actor OpenAITokenizer: TokenizerPort {

    /// BPE encoder implementing cl100k_base algorithm
    private let bpeEncoder: BytePairEncoder

    public init() throws {
        self.bpeEncoder = try BytePairEncoder()
    }

    public func countTokens(in text: String) async throws -> Int {
        guard !text.isEmpty else { return 0 }

        return await bpeEncoder.countTokens(in: text)
    }

    public func encode(_ text: String) async throws -> [Int] {
        guard !text.isEmpty else { return [] }

        return await bpeEncoder.encode(text)
    }

    public func decode(_ tokens: [Int]) async throws -> String {
        do {
            return try await bpeEncoder.decode(tokens)
        } catch {
            throw TokenizationError.decodingFailed(
                reason: "OpenAI tokenizer requires cl100k_base vocabulary for decoding: \(error)"
            )
        }
    }

    public func truncate(
        _ text: String,
        to maxTokens: Int
    ) async throws -> String {
        guard maxTokens > 0 else {
            throw TokenizationError.invalidInput(reason: "maxTokens must be positive")
        }

        let currentTokens = try await countTokens(in: text)

        guard currentTokens > maxTokens else {
            return text
        }

        // Binary search for optimal truncation point
        return try await binarySearchTruncate(text: text, targetTokens: maxTokens)
    }

    public nonisolated var provider: TokenizerProvider {
        .openai
    }

    // MARK: - Private Methods

    /// Binary search for optimal truncation that respects token boundaries
    private func binarySearchTruncate(text: String, targetTokens: Int) async throws -> String {
        var low = 0
        var high = text.count
        var result = ""

        while low <= high {
            let mid = (low + high) / 2
            let truncated = String(text.prefix(mid))
            let tokens = try await countTokens(in: truncated)

            if tokens <= targetTokens {
                result = truncated
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        // Try to truncate at word boundary for cleaner output
        if let lastSpace = result.lastIndex(of: " "), lastSpace != result.startIndex {
            let wordBoundaryResult = String(result[...lastSpace])
            let wordBoundaryTokens = try await countTokens(in: wordBoundaryResult)
            if wordBoundaryTokens <= targetTokens {
                return wordBoundaryResult
            }
        }

        return result
    }
}

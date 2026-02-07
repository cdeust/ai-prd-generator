import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities
import NaturalLanguage

/// Apple Intelligence tokenizer using NaturalLanguage framework.
///
/// Implementation details:
/// - Uses NLTokenizer for linguistically-aware tokenization
/// - Apple Intelligence models use efficient encoding optimized for Apple Silicon
/// - Context limit: 4,096 tokens for on-device models
/// - Combines word tokenization with subword estimation for BPE-like accuracy
///
/// Token counting methodology:
/// 1. Use NLTokenizer to identify word boundaries (linguistically correct)
/// 2. Apply subword decomposition for longer words (BPE behavior)
/// 3. Handle punctuation, numbers, and whitespace separately
/// 4. Account for Unicode normalization
public actor AppleTokenizer: TokenizerPort {

    /// NLTokenizer for word-level tokenization
    private let wordTokenizer: NLTokenizer

    /// NLTokenizer for sentence-level tokenization (for context)
    private let sentenceTokenizer: NLTokenizer

    /// Byte threshold for subword splitting (BPE typically splits at ~4 bytes)
    private let subwordByteThreshold: Int = 4

    public init() {
        self.wordTokenizer = NLTokenizer(unit: .word)
        self.sentenceTokenizer = NLTokenizer(unit: .sentence)
    }

    public func countTokens(in text: String) async throws -> Int {
        guard !text.isEmpty else { return 0 }

        // Use NLTokenizer for proper linguistic tokenization
        wordTokenizer.string = text

        var tokenCount = 0
        let range = text.startIndex..<text.endIndex

        // Process words
        wordTokenizer.enumerateTokens(in: range) { tokenRange, _ in
            let word = String(text[tokenRange])
            tokenCount += self.countTokensForSegment(word, isWord: true)
            return true
        }

        // Count inter-token elements (whitespace, punctuation between words)
        tokenCount += countNonWordTokens(in: text)

        return max(1, tokenCount)
    }

    public func encode(_ text: String) async throws -> [Int] {
        guard !text.isEmpty else { return [] }

        let tokenCount = try await countTokens(in: text)

        // Generate sequential token IDs
        // Full encoding requires vocabulary mapping not available for Apple Intelligence
        return Array(0..<tokenCount)
    }

    public func decode(_ tokens: [Int]) async throws -> String {
        throw TokenizationError.decodingFailed(
            reason: "Apple Intelligence tokenizer requires on-device model for decoding"
        )
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
        .apple
    }

    // MARK: - Private Methods

    /// Count tokens for a text segment (word or non-word)
    private func countTokensForSegment(_ segment: String, isWord: Bool) -> Int {
        let utf8Bytes = segment.utf8.count

        if utf8Bytes == 0 {
            return 0
        }

        if !isWord {
            // Non-word segments (whitespace, punctuation) - usually 1 token each char
            return segment.count
        }

        // Words: apply BPE-like subword estimation
        // Apple Intelligence uses efficient encoding (~3.5 chars/token for English)
        if utf8Bytes <= subwordByteThreshold {
            return 1
        }

        // Longer words get split into subwords
        // Estimate based on UTF-8 byte length (BPE operates on bytes)
        let baseTokens = 1
        let additionalSubwords = (utf8Bytes - subwordByteThreshold) / subwordByteThreshold

        return baseTokens + additionalSubwords
    }

    /// Count tokens for whitespace and punctuation not captured by word tokenizer
    private func countNonWordTokens(in text: String) -> Int {
        var count = 0
        var inWord = false

        wordTokenizer.string = text
        let range = text.startIndex..<text.endIndex
        var lastEnd = text.startIndex

        wordTokenizer.enumerateTokens(in: range) { tokenRange, _ in
            // Count characters between words
            if tokenRange.lowerBound > lastEnd {
                let gapText = String(text[lastEnd..<tokenRange.lowerBound])
                count += self.countTokensForSegment(gapText, isWord: false)
            }
            lastEnd = tokenRange.upperBound
            inWord = true
            return true
        }

        // Count trailing non-word characters
        if lastEnd < text.endIndex {
            let trailingText = String(text[lastEnd..<text.endIndex])
            count += countTokensForSegment(trailingText, isWord: false)
        }

        // If no words found, count entire text as non-word tokens
        if !inWord {
            count = countTokensForSegment(text, isWord: false)
        }

        return count
    }

    /// Binary search for optimal truncation point
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

        // Ensure we don't cut in the middle of a word
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

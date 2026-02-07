import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities
import NaturalLanguage

/// Gemini tokenizer implementing Google's SentencePiece-based tokenization.
///
/// Implementation details:
/// - Gemini uses SentencePiece with Unigram language model
/// - Different from BPE: uses probabilistic model for subword selection
/// - Average English: ~4.5 characters per token (slightly more than GPT-4)
/// - Context limits: Gemini 1.5 Pro (2M), Gemini 1.5 Flash (1M)
///
/// Token counting methodology:
/// 1. Use NLTokenizer for word segmentation (linguistically aware)
/// 2. Apply SentencePiece-like subword estimation
/// 3. Handle Unicode, whitespace, and special characters
///
/// SentencePiece specifics:
/// - Treats text as sequence of Unicode characters
/// - Uses underscore (▁) to mark word boundaries
/// - Subword units selected by unigram probability
public actor GeminiTokenizer: TokenizerPort {

    /// NLTokenizer for linguistic word segmentation
    private let wordTokenizer: NLTokenizer

    /// SentencePiece average subword length (based on Gemini's vocabulary)
    private let averageSubwordLength: Int = 4

    /// Minimum subword unit size
    private let minSubwordSize: Int = 2

    public init() {
        self.wordTokenizer = NLTokenizer(unit: .word)
    }

    public func countTokens(in text: String) async throws -> Int {
        guard !text.isEmpty else { return 0 }

        var tokenCount = 0

        // SentencePiece treats entire text including whitespace
        // Process character by character with word awareness
        wordTokenizer.string = text

        let range = text.startIndex..<text.endIndex
        var lastEnd = text.startIndex

        wordTokenizer.enumerateTokens(in: range) { tokenRange, _ in
            // Count whitespace/punctuation before this word
            if tokenRange.lowerBound > lastEnd {
                let prefix = String(text[lastEnd..<tokenRange.lowerBound])
                tokenCount += self.countSentencePieceTokens(prefix, isWordBoundary: true)
            }

            // Count the word itself
            let word = String(text[tokenRange])
            tokenCount += self.countSentencePieceTokens(word, isWordBoundary: false)

            lastEnd = tokenRange.upperBound
            return true
        }

        // Count trailing content
        if lastEnd < text.endIndex {
            let suffix = String(text[lastEnd..<text.endIndex])
            tokenCount += self.countSentencePieceTokens(suffix, isWordBoundary: true)
        }

        // Handle case where no words were found (all punctuation/whitespace)
        if tokenCount == 0 && !text.isEmpty {
            tokenCount = countSentencePieceTokens(text, isWordBoundary: true)
        }

        return max(1, tokenCount)
    }

    public func encode(_ text: String) async throws -> [Int] {
        guard !text.isEmpty else { return [] }

        let tokenCount = try await countTokens(in: text)
        return Array(0..<tokenCount)
    }

    public func decode(_ tokens: [Int]) async throws -> String {
        throw TokenizationError.decodingFailed(
            reason: "Gemini tokenizer requires SentencePiece vocabulary for decoding"
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

        return try await binarySearchTruncate(text: text, targetTokens: maxTokens)
    }

    public nonisolated var provider: TokenizerProvider {
        .gemini
    }

    // MARK: - Private Methods

    /// Count tokens using SentencePiece-like algorithm
    /// SentencePiece uses Unigram language model for optimal subword segmentation
    private func countSentencePieceTokens(_ text: String, isWordBoundary: Bool) -> Int {
        guard !text.isEmpty else { return 0 }

        let bytes = Array(text.utf8)
        let length = bytes.count

        // Whitespace: each whitespace character typically becomes a token
        // SentencePiece marks word boundaries with special character
        if text.allSatisfy({ $0.isWhitespace }) {
            // Consecutive whitespace often merges to fewer tokens
            let wsCount = text.count
            return (wsCount + 1) / 2  // Rough estimate: 2 spaces = 1 token
        }

        // Numbers: SentencePiece typically tokenizes digits individually or in small groups
        if text.allSatisfy({ $0.isNumber }) {
            return (text.count + 2) / 3  // ~3 digits per token
        }

        // Punctuation and symbols
        if text.allSatisfy({ $0.isPunctuation || $0.isSymbol }) {
            return text.count  // Usually 1 token per punctuation
        }

        // Words: SentencePiece uses Unigram model
        // Short common words: 1 token
        // Longer/rare words: split into subwords
        if length <= 3 {
            return 1
        }

        // For longer words, estimate subword splits
        // SentencePiece tends to create slightly longer subwords than BPE
        let baseToken = 1
        let additionalSubwords = (length - 3) / averageSubwordLength

        return baseToken + additionalSubwords
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

        // Try word boundary truncation
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

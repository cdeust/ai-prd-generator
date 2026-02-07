import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities
import NaturalLanguage

/// Generic tokenizer for OpenRouter's unified API.
///
/// OpenRouter routes to 100+ models from different providers.
/// Since the exact model may vary, this tokenizer uses a robust
/// generic approach that works reasonably well across all models.
///
/// Implementation strategy:
/// - Uses NLTokenizer for linguistically-aware word segmentation
/// - Applies conservative BPE estimation (~4 chars/token average)
/// - Works with any model without requiring model-specific vocabulary
///
/// For optimal accuracy, configure with the target model family
/// if known at initialization time.
///
/// Supported model families:
/// - OpenAI (GPT-4, GPT-4 Turbo)
/// - Anthropic (Claude 3.x)
/// - Google (Gemini, PaLM)
/// - Meta (Llama 2, Llama 3)
/// - Mistral (Mistral, Mixtral)
/// - And 100+ more models
public actor OpenRouterTokenizer: TokenizerPort {

    /// NLTokenizer for word segmentation
    private let wordTokenizer: NLTokenizer

    /// Model family for this instance
    private let modelFamily: OpenRouterModelFamily

    /// Average characters per token (varies by model family)
    private var charsPerToken: Double {
        switch modelFamily {
        case .openai, .anthropic, .mistral:
            return 4.0
        case .google:
            return 4.5
        case .meta:
            return 3.8
        case .cohere:
            return 4.2
        case .generic:
            return 4.0  // Conservative default
        }
    }

    /// Create generic tokenizer (default: generic model family)
    public init(modelFamily: OpenRouterModelFamily = .generic) {
        self.wordTokenizer = NLTokenizer(unit: .word)
        self.modelFamily = modelFamily
    }

    /// Create tokenizer by detecting model family from model name
    /// - Parameter modelName: OpenRouter model name (e.g., "anthropic/claude-3-sonnet")
    public init(modelName: String) {
        self.wordTokenizer = NLTokenizer(unit: .word)
        self.modelFamily = Self.detectModelFamily(from: modelName)
    }

    public func countTokens(in text: String) async throws -> Int {
        guard !text.isEmpty else { return 0 }

        var tokenCount = 0
        wordTokenizer.string = text

        let range = text.startIndex..<text.endIndex
        var lastEnd = text.startIndex

        wordTokenizer.enumerateTokens(in: range) { tokenRange, _ in
            // Count whitespace/punctuation between words
            if tokenRange.lowerBound > lastEnd {
                let gap = String(text[lastEnd..<tokenRange.lowerBound])
                tokenCount += self.countTokensForSegment(gap)
            }

            // Count the word
            let word = String(text[tokenRange])
            tokenCount += self.countTokensForSegment(word)

            lastEnd = tokenRange.upperBound
            return true
        }

        // Count trailing content
        if lastEnd < text.endIndex {
            let trailing = String(text[lastEnd..<text.endIndex])
            tokenCount += countTokensForSegment(trailing)
        }

        // Handle pure whitespace/punctuation text
        if tokenCount == 0 && !text.isEmpty {
            tokenCount = countTokensForSegment(text)
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
            reason: "OpenRouter generic tokenizer cannot decode without model-specific vocabulary"
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
        .openRouter
    }

    // MARK: - Private Methods

    /// Count tokens for a text segment using generic BPE estimation
    private func countTokensForSegment(_ segment: String) -> Int {
        guard !segment.isEmpty else { return 0 }

        let bytes = segment.utf8.count

        // Whitespace
        if segment.allSatisfy({ $0.isWhitespace }) {
            return segment.count
        }

        // Numbers
        if segment.allSatisfy({ $0.isNumber }) {
            return (segment.count + 2) / 3
        }

        // Punctuation
        if segment.allSatisfy({ $0.isPunctuation || $0.isSymbol }) {
            return segment.count
        }

        // Words: use model-family-specific chars per token
        let estimatedTokens = Double(bytes) / charsPerToken
        return max(1, Int(ceil(estimatedTokens)))
    }

    /// Binary search for optimal truncation
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

        // Prefer word boundary
        if let lastSpace = result.lastIndex(of: " "), lastSpace != result.startIndex {
            let wordBoundaryResult = String(result[...lastSpace])
            let wordBoundaryTokens = try await countTokens(in: wordBoundaryResult)
            if wordBoundaryTokens <= targetTokens {
                return wordBoundaryResult
            }
        }

        return result
    }

    // MARK: - Model Detection

    /// Detect model family from OpenRouter model name
    private static func detectModelFamily(from modelName: String) -> OpenRouterModelFamily {
        let lowercased = modelName.lowercased()

        if lowercased.contains("openai") || lowercased.contains("gpt") {
            return .openai
        }
        if lowercased.contains("anthropic") || lowercased.contains("claude") {
            return .anthropic
        }
        if lowercased.contains("google") || lowercased.contains("gemini") || lowercased.contains("palm") {
            return .google
        }
        if lowercased.contains("meta") || lowercased.contains("llama") {
            return .meta
        }
        if lowercased.contains("mistral") || lowercased.contains("mixtral") {
            return .mistral
        }
        if lowercased.contains("cohere") || lowercased.contains("command") {
            return .cohere
        }

        return .generic
    }
}

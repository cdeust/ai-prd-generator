import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// AWS Bedrock tokenizer that adapts to the underlying model.
///
/// Bedrock supports multiple model families with different tokenizers:
/// - Claude models: Use Anthropic's modified tiktoken
/// - Amazon Titan: Uses custom tokenizer (~4 chars/token)
/// - Meta Llama: Uses SentencePiece tokenizer
///
/// Implementation:
/// - Delegates to model-specific tokenizer based on configured model
/// - Default: Claude tokenizer (most common Bedrock use case)
///
/// Context limits vary by model:
/// - Claude 3.5 Sonnet: 200K tokens
/// - Amazon Titan Text: 8K tokens
/// - Llama 3: 8K tokens
public actor BedrockTokenizer: TokenizerPort {

    /// Underlying tokenizer based on model family
    private let underlyingTokenizer: any TokenizerPort

    /// Model family this tokenizer is configured for
    private let modelFamily: BedrockModelFamily

    /// Create tokenizer for specific Bedrock model family
    /// - Parameter modelFamily: The model family to use (default: Claude)
    public init(modelFamily: BedrockModelFamily = .claude) throws {
        self.modelFamily = modelFamily

        switch modelFamily {
        case .claude, .mistral:
            // Claude and Mistral use similar BPE tokenization
            self.underlyingTokenizer = try ClaudeTokenizer()
        case .titan, .cohere:
            // Titan and Cohere use BPE similar to OpenAI
            self.underlyingTokenizer = try OpenAITokenizer()
        case .llama:
            // Llama uses SentencePiece (similar to Gemini)
            self.underlyingTokenizer = GeminiTokenizer()
        }
    }

    /// Create tokenizer by detecting model from model ID
    /// - Parameter modelId: Bedrock model ID (e.g., "anthropic.claude-3-sonnet-20240229-v1:0")
    public init(modelId: String) throws {
        let family = Self.detectModelFamily(from: modelId)
        try self.init(modelFamily: family)
    }

    public func countTokens(in text: String) async throws -> Int {
        try await underlyingTokenizer.countTokens(in: text)
    }

    public func encode(_ text: String) async throws -> [Int] {
        try await underlyingTokenizer.encode(text)
    }

    public func decode(_ tokens: [Int]) async throws -> String {
        try await underlyingTokenizer.decode(tokens)
    }

    public func truncate(
        _ text: String,
        to maxTokens: Int
    ) async throws -> String {
        try await underlyingTokenizer.truncate(text, to: maxTokens)
    }

    public nonisolated var provider: TokenizerProvider {
        .bedrock
    }

    // MARK: - Model Detection

    /// Detect model family from Bedrock model ID
    private static func detectModelFamily(from modelId: String) -> BedrockModelFamily {
        let lowercased = modelId.lowercased()

        if lowercased.contains("anthropic") || lowercased.contains("claude") {
            return .claude
        }
        if lowercased.contains("amazon") || lowercased.contains("titan") {
            return .titan
        }
        if lowercased.contains("meta") || lowercased.contains("llama") {
            return .llama
        }
        if lowercased.contains("mistral") {
            return .mistral
        }
        if lowercased.contains("cohere") || lowercased.contains("command") {
            return .cohere
        }

        // Default to Claude (most common Bedrock model)
        return .claude
    }
}

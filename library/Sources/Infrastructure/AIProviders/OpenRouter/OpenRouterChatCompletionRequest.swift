import Foundation

/// OpenRouter Reasoning Configuration
/// Enables extended thinking with token budget
struct OpenRouterReasoningConfig: Codable {
    let enabled: Bool
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case enabled
        case maxTokens = "max_tokens"
    }
}

/// OpenRouter Chat Completion Request DTO
/// Maps to OpenRouter API request format (OpenAI-compatible with extensions)
struct OpenRouterChatCompletionRequest: Codable {
    let model: String
    let messages: [[String: String]]  // Simplified message format
    let maxTokens: Int?
    let temperature: Double
    let stream: Bool
    let reasoning: OpenRouterReasoningConfig?

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream, reasoning
        case maxTokens = "max_tokens"
    }
}

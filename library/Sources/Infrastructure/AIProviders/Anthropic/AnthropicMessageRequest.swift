import Foundation

/// Anthropic Extended Thinking Configuration
/// Enables Claude's extended thinking mode with token budget
struct AnthropicThinkingConfig: Codable {
    let type: String
    let budgetTokens: Int

    enum CodingKeys: String, CodingKey {
        case type
        case budgetTokens = "budget_tokens"
    }

    /// Default configuration with 50K token budget
    static var `default`: AnthropicThinkingConfig {
        AnthropicThinkingConfig(type: "enabled", budgetTokens: 50_000)
    }
}

/// Anthropic Message Request DTO
/// Maps to Anthropic Messages API request format
struct AnthropicMessageRequest: Codable {
    let model: String
    let messages: [AnthropicMessage]
    let maxTokens: Int
    let temperature: Double
    let stream: Bool
    let thinking: AnthropicThinkingConfig?

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream, thinking
        case maxTokens = "max_tokens"
    }
}

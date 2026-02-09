import Foundation
import AIPRDSharedUtilities

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

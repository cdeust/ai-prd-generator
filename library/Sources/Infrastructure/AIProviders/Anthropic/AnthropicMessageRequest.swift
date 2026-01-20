import Foundation

/// Anthropic Message Request DTO
/// Maps to Anthropic Messages API request format
struct AnthropicMessageRequest: Codable {
    let model: String
    let messages: [AnthropicMessage]
    let maxTokens: Int
    let temperature: Double
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream
        case maxTokens = "max_tokens"
    }
}

import Foundation

/// OpenAI Chat Completion Request DTO
/// Maps to OpenAI API request format
struct OpenAIChatCompletionRequest: Codable {
    let model: String
    let messages: [OpenAIChatMessage]
    let maxTokens: Int?  // Optional - nil means generate until natural completion
    let temperature: Double
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream
        case maxTokens = "max_tokens"
    }
}

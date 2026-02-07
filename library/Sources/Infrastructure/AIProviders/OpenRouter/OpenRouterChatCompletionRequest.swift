import Foundation
import AIPRDSharedUtilities

/// OpenRouter Chat Completion Request DTO
/// Maps to OpenRouter API request format (OpenAI-compatible with extensions)
struct OpenRouterChatCompletionRequest: Codable {
    let model: String
    let messages: [[String: String]]
    let maxTokens: Int?
    let temperature: Double
    let stream: Bool
    let reasoning: OpenRouterReasoningConfig?

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream, reasoning
        case maxTokens = "max_tokens"
    }
}

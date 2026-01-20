import Foundation

/// Claude Vision API request DTO
struct AnthropicVisionRequest: Codable, Sendable {
    let model: String
    let messages: [AnthropicVisionMessage]
    let maxTokens: Int
    let temperature: Double
    let stream: Bool?

    init(
        model: String,
        messages: [AnthropicVisionMessage],
        maxTokens: Int,
        temperature: Double,
        stream: Bool? = nil
    ) {
        self.model = model
        self.messages = messages
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.stream = stream
    }

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case temperature
        case stream
    }
}


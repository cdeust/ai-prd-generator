import Foundation

/// Anthropic Message DTO
/// Represents a single message in the conversation
struct AnthropicMessage: Codable {
    let role: String
    let content: String
}

import AIPRDSharedUtilities
import Foundation

/// OpenAI Chat Message DTO
/// Represents a single message in the conversation
struct OpenAIChatMessage: Codable {
    let role: String
    let content: String
}

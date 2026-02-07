import AIPRDSharedUtilities
import Foundation

/// OpenAI Chat Completion Response Message
/// Represents the message content in a choice
struct OpenAIChatCompletionResponseMessage: Codable {
    let content: String
}

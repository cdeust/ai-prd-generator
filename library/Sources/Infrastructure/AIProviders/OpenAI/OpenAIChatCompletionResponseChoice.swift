import AIPRDSharedUtilities
import Foundation

/// OpenAI Chat Completion Response Choice
/// Represents a single choice in the response
struct OpenAIChatCompletionResponseChoice: Codable {
    let message: OpenAIChatCompletionResponseMessage
}

import AIPRDSharedUtilities
import Foundation

/// OpenAI Chat Completion Response DTO
/// Maps to OpenAI API response format
struct OpenAIChatCompletionResponse: Codable {
    let choices: [OpenAIChatCompletionResponseChoice]
}

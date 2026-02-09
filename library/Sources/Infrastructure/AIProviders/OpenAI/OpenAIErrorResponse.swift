import AIPRDSharedUtilities
import Foundation

/// OpenAI Error Response DTO
/// Maps to OpenAI API error format
struct OpenAIErrorResponse: Codable {
    let error: OpenAIErrorDetail
}

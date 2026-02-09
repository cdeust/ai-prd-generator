import AIPRDSharedUtilities
import Foundation

/// Anthropic Error Response DTO
/// Maps to Anthropic API error format
struct AnthropicErrorResponse: Codable {
    let error: AnthropicErrorDetail
}

import Foundation
import AIPRDSharedUtilities

/// Anthropic Message Response DTO
/// Maps to Anthropic Messages API response format
struct AnthropicMessageResponse: Codable {
    let content: [AnthropicMessageResponseContent]
    let usage: AnthropicUsage?
}

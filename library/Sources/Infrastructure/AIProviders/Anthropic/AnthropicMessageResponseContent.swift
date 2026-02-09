import AIPRDSharedUtilities
import Foundation

/// Anthropic Message Response Content
/// Represents a content block in the response
struct AnthropicMessageResponseContent: Codable {
    let text: String?
    let type: String
}

import Foundation

/// Claude Vision message with role and multi-modal content
struct AnthropicVisionMessage: Codable, Sendable {
    let role: String
    let content: [AnthropicVisionContent]
}


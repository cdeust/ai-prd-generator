import Foundation

/// Anthropic streaming response chunk
struct AnthropicResponseChunk: Codable, Sendable {
    let type: String
    let delta: Delta?

    struct Delta: Codable, Sendable {
        let type: String
        let text: String?
    }
}


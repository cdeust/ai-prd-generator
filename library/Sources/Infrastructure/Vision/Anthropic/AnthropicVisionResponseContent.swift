import Foundation

/// Response content block
struct AnthropicVisionResponseContent: Codable, Sendable {
    let type: String
    let text: String?
}


import Foundation

/// Claude Vision API response
struct AnthropicVisionResponse: Codable, Sendable {
    let id: String
    let type: String
    let role: String
    let content: [AnthropicVisionResponseContent]
    let model: String
    let stopReason: String?
    let usage: AnthropicVisionUsage

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case role
        case content
        case model
        case stopReason = "stop_reason"
        case usage
    }
}


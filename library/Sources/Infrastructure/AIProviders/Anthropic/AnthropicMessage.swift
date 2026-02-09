import Foundation
import AIPRDSharedUtilities

/// Anthropic Message DTO
/// Represents a single message in the conversation
/// Supports both simple string content and structured content with cache control
struct AnthropicMessage: Codable {
    let role: String
    let content: AnthropicMessageContent

    init(role: String, content: String) {
        self.role = role
        self.content = .simple(content)
    }

    init(role: String, contentBlocks: [AnthropicContentBlock]) {
        self.role = role
        self.content = .structured(contentBlocks)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)

        switch content {
        case .simple(let text):
            try container.encode(text, forKey: .content)
        case .structured(let blocks):
            try container.encode(blocks, forKey: .content)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        role = try container.decode(String.self, forKey: .role)

        if let text = try? container.decode(String.self, forKey: .content) {
            content = .simple(text)
        } else {
            let blocks = try container.decode([AnthropicContentBlock].self, forKey: .content)
            content = .structured(blocks)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case role, content
    }
}

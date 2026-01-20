import Foundation

/// Multi-modal content block (text or image)
enum AnthropicVisionContent: Codable, Sendable {
    case text(String)
    case image(AnthropicVisionImageBlock)

    enum CodingKeys: String, CodingKey {
        case type
        case text
        case source
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let value):
            try container.encode("text", forKey: .type)
            try container.encode(value, forKey: .text)

        case .image(let block):
            try container.encode("image", forKey: .type)
            try container.encode(block, forKey: .source)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)

        case "image":
            let block = try container.decode(AnthropicVisionImageBlock.self, forKey: .source)
            self = .image(block)

        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown content type: \(type)"
            )
        }
    }
}


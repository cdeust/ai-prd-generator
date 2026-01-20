import Foundation

/// Image source block for Claude Vision
struct AnthropicVisionImageBlock: Codable, Sendable {
    let type: String
    let mediaType: String
    let data: String

    enum CodingKeys: String, CodingKey {
        case type
        case mediaType = "media_type"
        case data
    }

    init(imageData: Data, mimeType: String) {
        self.type = "base64"
        self.mediaType = mimeType
        self.data = imageData.base64EncodedString()
    }
}


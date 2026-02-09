import AIPRDSharedUtilities
import Foundation

/// Gemini Content DTO
/// Represents content with parts
struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

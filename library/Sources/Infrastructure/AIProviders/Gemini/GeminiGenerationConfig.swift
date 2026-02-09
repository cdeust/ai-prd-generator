import AIPRDSharedUtilities
import Foundation

/// Gemini Generation Configuration DTO
/// Controls generation parameters
struct GeminiGenerationConfig: Codable {
    let maxOutputTokens: Int?  // Optional - omit to let model decide naturally
    let temperature: Double
    let thinkingLevel: String?  // Gemini 3.0: MINIMAL, LOW, MEDIUM, HIGH

    enum CodingKeys: String, CodingKey {
        case maxOutputTokens, temperature
        case thinkingLevel = "thinking_level"
    }
}

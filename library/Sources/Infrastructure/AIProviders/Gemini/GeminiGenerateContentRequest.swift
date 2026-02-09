import AIPRDSharedUtilities
import Foundation

/// Gemini Generate Content Request DTO
/// Maps to Gemini API request format
struct GeminiGenerateContentRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

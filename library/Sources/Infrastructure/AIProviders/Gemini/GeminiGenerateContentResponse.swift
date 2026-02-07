import AIPRDSharedUtilities
import Foundation

/// Gemini Generate Content Response DTO
/// Maps to Gemini API response format
struct GeminiGenerateContentResponse: Codable {
    let candidates: [GeminiGenerateContentResponseCandidate]
}

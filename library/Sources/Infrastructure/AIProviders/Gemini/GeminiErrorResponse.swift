import AIPRDSharedUtilities
import Foundation

/// Gemini Error Response DTO
/// Maps to Gemini API error format
struct GeminiErrorResponse: Codable {
    let error: GeminiErrorDetail
}

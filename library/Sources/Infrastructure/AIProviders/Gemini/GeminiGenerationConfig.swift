import Foundation

/// Gemini Generation Configuration DTO
/// Controls generation parameters
struct GeminiGenerationConfig: Codable {
    let maxOutputTokens: Int?  // Optional - omit to let model decide naturally
    let temperature: Double
}

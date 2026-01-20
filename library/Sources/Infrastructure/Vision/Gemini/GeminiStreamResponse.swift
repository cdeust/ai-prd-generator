import Foundation

/// Gemini streaming chunk
enum GeminiStreamResponse: Sendable {
    case content(GeminiResponseChunk)
    case done
}


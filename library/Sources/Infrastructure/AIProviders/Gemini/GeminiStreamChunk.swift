import AIPRDSharedUtilities
import Foundation

/// Gemini Streaming Response Chunk DTO
/// Represents a single chunk in a streaming response
struct GeminiStreamChunk: Codable {
    let candidates: [GeminiStreamChunkCandidate]
}

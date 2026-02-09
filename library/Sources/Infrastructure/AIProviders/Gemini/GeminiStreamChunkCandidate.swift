import AIPRDSharedUtilities
import Foundation

/// Gemini Stream Chunk Candidate
/// Represents a candidate in a stream chunk
struct GeminiStreamChunkCandidate: Codable {
    let content: GeminiContent
}

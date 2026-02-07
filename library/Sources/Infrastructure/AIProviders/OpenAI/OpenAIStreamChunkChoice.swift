import AIPRDSharedUtilities
import Foundation

/// OpenAI Stream Chunk Choice
/// Represents a single choice in a stream chunk
struct OpenAIStreamChunkChoice: Codable {
    let delta: OpenAIStreamChunkDelta
}

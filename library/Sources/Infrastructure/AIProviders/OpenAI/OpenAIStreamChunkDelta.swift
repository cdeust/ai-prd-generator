import AIPRDSharedUtilities
import Foundation

/// OpenAI Stream Chunk Delta
/// Represents incremental content in a stream chunk
struct OpenAIStreamChunkDelta: Codable {
    let content: String?
}

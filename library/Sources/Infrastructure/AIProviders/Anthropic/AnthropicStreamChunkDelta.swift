import AIPRDSharedUtilities
import Foundation

/// Anthropic Stream Chunk Delta
/// Represents incremental content in a stream chunk
struct AnthropicStreamChunkDelta: Codable {
    let text: String?
}

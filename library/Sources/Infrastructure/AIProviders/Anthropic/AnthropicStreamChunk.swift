import AIPRDSharedUtilities
import Foundation

/// Anthropic Streaming Response Chunk DTO
/// Represents a single chunk in a streaming response
struct AnthropicStreamChunk: Codable {
    let type: String
    let delta: AnthropicStreamChunkDelta?
}

import AIPRDSharedUtilities
import Foundation

/// OpenAI Streaming Response Chunk DTO
/// Represents a single chunk in a streaming response
struct OpenAIStreamChunk: Codable {
    let choices: [OpenAIStreamChunkChoice]
}

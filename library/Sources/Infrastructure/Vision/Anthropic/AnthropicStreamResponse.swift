import Foundation

/// Streaming chunk from Anthropic
enum AnthropicStreamResponse: Sendable {
    case content(AnthropicResponseChunk)
    case done
}


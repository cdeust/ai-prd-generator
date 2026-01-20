import Foundation

/// OpenAI streaming chunk
enum OpenAIStreamResponse: Sendable {
    case content(OpenAIResponseChunk)
    case done
}


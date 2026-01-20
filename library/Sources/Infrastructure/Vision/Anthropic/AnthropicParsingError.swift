import Foundation

/// Parsing errors for Anthropic responses
enum AnthropicParsingError: Error, Sendable {
    case invalidUTF8
    case noMarkdownCodeBlock
    case noJSONBrackets
    case failedAfterAllStrategies(attempt: Int)
}


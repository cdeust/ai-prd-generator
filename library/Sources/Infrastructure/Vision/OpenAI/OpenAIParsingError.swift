import Foundation

/// Parsing errors for OpenAI responses
enum OpenAIParsingError: Error, Sendable {
    case invalidUTF8
    case noMarkdownCodeBlock
    case noCodeBlock
    case noJSONBrackets
    case failedAfterAllStrategies(attempt: Int)
}


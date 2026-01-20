import Foundation

/// Parsing errors for Gemini responses
enum GeminiParsingError: Error, Sendable {
    case invalidUTF8
    case noMarkdownCodeBlock
    case noCodeBlock
    case noJSONBrackets
    case failedAfterAllStrategies(attempt: Int)
}


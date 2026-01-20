import Foundation

/// Parsing errors for code analysis
/// Domain error for code parsing operations
public enum CodeParsingError: Error {
    case unsupportedLanguage(ProgrammingLanguage)
    case syntaxError(line: Int, message: String)
    case parsingFailed(reason: String)
}

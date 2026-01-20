import Foundation

/// Port for parsing source code into semantic chunks
/// Domain defines the interface, Infrastructure implements it
public protocol CodeParserPort: Sendable {
    /// The programming language this parser supports
    var supportedLanguage: ProgrammingLanguage { get }

    /// Parse code into semantic chunks
    /// - Parameters:
    ///   - code: Source code to parse
    ///   - filePath: File path for context
    /// - Returns: Array of parsed code chunks
    func parseCode(_ code: String, filePath: String) async throws -> [ParsedCodeChunk]

    /// Extract symbols from code
    /// - Parameters:
    ///   - code: Source code
    ///   - filePath: File path
    /// - Returns: Array of code symbols
    func extractSymbols(_ code: String, filePath: String) async throws -> [CodeSymbol]
}

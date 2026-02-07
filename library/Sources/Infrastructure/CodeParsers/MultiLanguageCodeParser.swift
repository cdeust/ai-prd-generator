import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Multi-language Code Parser
/// Routes parsing to appropriate parser based on file extension
/// Uses specialized parsers when available, generic fallback otherwise
public final class MultiLanguageCodeParser: CodeParserPort, Sendable {
    private let swiftParser: SwiftCodeParser
    private let genericParser: GenericCodeParser

    public init() {
        self.swiftParser = SwiftCodeParser()
        self.genericParser = GenericCodeParser()
    }

    public var supportedLanguage: ProgrammingLanguage { .unknown }

    public func parseCode(_ code: String, filePath: String) async throws -> [ParsedCodeChunk] {
        let ext = (filePath as NSString).pathExtension.lowercased()

        // Use specialized Swift parser for Swift files
        if ext == "swift" {
            return try await swiftParser.parseCode(code, filePath: filePath)
        }

        // Use generic parser for all other languages
        return try await genericParser.parseCode(code, filePath: filePath)
    }

    public func extractSymbols(_ code: String, filePath: String) async throws -> [CodeSymbol] {
        let ext = (filePath as NSString).pathExtension.lowercased()

        if ext == "swift" {
            return try await swiftParser.extractSymbols(code, filePath: filePath)
        }

        return try await genericParser.extractSymbols(code, filePath: filePath)
    }
}

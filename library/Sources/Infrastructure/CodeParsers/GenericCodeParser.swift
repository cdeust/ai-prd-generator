import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Generic Code Parser Implementation
/// Extracts imports from any programming language using pattern matching
public final class GenericCodeParser: CodeParserPort, Sendable {
    private let maxChunkSize: Int
    private let importExtractor: ImportExtractor

    public init(maxChunkSize: Int = 1000) {
        self.maxChunkSize = maxChunkSize
        self.importExtractor = ImportExtractor()
    }

    public var supportedLanguage: ProgrammingLanguage { .unknown }

    public func parseCode(_ code: String, filePath: String) async throws -> [ParsedCodeChunk] {
        let ext = (filePath as NSString).pathExtension.lowercased()
        let imports = importExtractor.extractImports(from: code, fileExtension: ext)
        return splitIntoChunks(code: code, imports: imports)
    }

    public func extractSymbols(_ code: String, filePath: String) async throws -> [CodeSymbol] {
        []
    }

    private func splitIntoChunks(code: String, imports: [String]) -> [ParsedCodeChunk] {
        let lines = code.components(separatedBy: .newlines)
        var chunks: [ParsedCodeChunk] = []
        var currentLines: [String] = []
        var startLine = 1

        for (index, line) in lines.enumerated() {
            currentLines.append(line)

            if currentLines.count >= maxChunkSize {
                chunks.append(createChunk(
                    content: currentLines.joined(separator: "\n"),
                    startLine: startLine,
                    endLine: index + 1,
                    imports: imports
                ))
                startLine = index + 2
                currentLines = []
            }
        }

        if !currentLines.isEmpty {
            chunks.append(createChunk(
                content: currentLines.joined(separator: "\n"),
                startLine: startLine,
                endLine: lines.count,
                imports: imports
            ))
        }

        return chunks.isEmpty ? [createChunk(
            content: code,
            startLine: 1,
            endLine: lines.count,
            imports: imports
        )] : chunks
    }

    private func createChunk(
        content: String,
        startLine: Int,
        endLine: Int,
        imports: [String]
    ) -> ParsedCodeChunk {
        ParsedCodeChunk(
            content: content,
            startLine: startLine,
            endLine: endLine,
            type: .function,
            symbols: [],
            imports: imports,
            tokenCount: content.split(separator: " ").count
        )
    }
}

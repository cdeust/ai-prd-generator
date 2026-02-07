import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Swift Code Parser Implementation
/// Implements CodeParserPort for Swift language
/// Single Responsibility: Coordinates Swift code parsing using specialized helpers
public final class SwiftCodeParser: CodeParserPort, Sendable {
    private let maxChunkSize: Int
    private let overlapLines: Int
    private let symbolExtractor: SwiftSymbolExtractor
    private let complexityCalculator: SwiftComplexityCalculator
    private let logicalUnitExtractor: SwiftLogicalUnitExtractor

    public init(
        maxChunkSize: Int = 1000,
        overlapLines: Int = 5
    ) {
        self.maxChunkSize = maxChunkSize
        self.overlapLines = overlapLines
        self.symbolExtractor = SwiftSymbolExtractor()
        self.complexityCalculator = SwiftComplexityCalculator()
        self.logicalUnitExtractor = SwiftLogicalUnitExtractor()
    }

    public var supportedLanguage: ProgrammingLanguage { .swift }

    public func parseCode(_ code: String, filePath: String) async throws -> [ParsedCodeChunk] {
        let imports = extractImports(from: code)
        let symbols = symbolExtractor.extractSymbols(from: code)
        let chunks = parseIntoChunks(code: code, imports: imports, symbols: symbols)

        return chunks
    }

    public func extractSymbols(_ code: String, filePath: String) async throws -> [CodeSymbol] {
        symbolExtractor.extractSymbols(from: code)
    }

    private func extractImports(from code: String) -> [String] {
        var imports: [String] = []
        let lines = code.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("import ") {
                let importName = trimmed
                    .replacingOccurrences(of: "import ", with: "")
                    .trimmingCharacters(in: .whitespaces)
                imports.append(importName)
            }
        }

        return imports
    }

    private func parseIntoChunks(
        code: String,
        imports: [String],
        symbols: [CodeSymbol]
    ) -> [ParsedCodeChunk] {
        let lines = code.components(separatedBy: .newlines)
        let logicalUnits = logicalUnitExtractor.extractLogicalUnits(from: code)
        let symbolNames = symbols.map { $0.name }

        if logicalUnits.isEmpty {
            return createSizeBasedChunks(
                lines: lines,
                imports: imports,
                symbols: symbolNames
            )
        } else {
            return createLogicalUnitChunks(
                units: logicalUnits,
                imports: imports,
                symbols: symbolNames
            )
        }
    }

    private func createSizeBasedChunks(
        lines: [String],
        imports: [String],
        symbols: [String]
    ) -> [ParsedCodeChunk] {
        let sizeBasedChunks = splitBySize(lines: lines)
        return sizeBasedChunks.enumerated().map { index, chunk in
            ParsedCodeChunk(
                content: chunk,
                startLine: index * maxChunkSize + 1,
                endLine: min((index + 1) * maxChunkSize, lines.count),
                type: .function,
                symbols: symbols,
                imports: imports,
                tokenCount: estimateTokens(chunk)
            )
        }
    }

    private func createLogicalUnitChunks(
        units: [LogicalUnit],
        imports: [String],
        symbols: [String]
    ) -> [ParsedCodeChunk] {
        units.map { unit in
            ParsedCodeChunk(
                content: unit.content,
                startLine: unit.startLine,
                endLine: unit.endLine,
                type: .function,
                symbols: [unit.name],
                imports: imports,
                tokenCount: estimateTokens(unit.content)
            )
        }
    }

    private func estimateTokens(_ text: String) -> Int {
        text.split(separator: " ").count
    }

    private func splitBySize(lines: [String]) -> [String] {
        var chunks: [String] = []
        var currentChunk: [String] = []

        for line in lines {
            currentChunk.append(line)

            if currentChunk.count >= maxChunkSize {
                chunks.append(currentChunk.joined(separator: "\n"))
                currentChunk = Array(currentChunk.suffix(overlapLines))
            }
        }

        if !currentChunk.isEmpty {
            chunks.append(currentChunk.joined(separator: "\n"))
        }

        return chunks
    }
}

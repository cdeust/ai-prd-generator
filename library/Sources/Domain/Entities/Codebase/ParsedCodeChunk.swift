import Foundation

/// Parsed code chunk
/// Domain entity representing a semantic code segment
public struct ParsedCodeChunk: Sendable {
    public let content: String
    public let startLine: Int
    public let endLine: Int
    public let type: ChunkType
    public let symbols: [String]
    public let imports: [String]
    public let tokenCount: Int

    public init(
        content: String,
        startLine: Int,
        endLine: Int,
        type: ChunkType,
        symbols: [String] = [],
        imports: [String] = [],
        tokenCount: Int = 0
    ) {
        self.content = content
        self.startLine = startLine
        self.endLine = endLine
        self.type = type
        self.symbols = symbols
        self.imports = imports
        self.tokenCount = tokenCount
    }
}

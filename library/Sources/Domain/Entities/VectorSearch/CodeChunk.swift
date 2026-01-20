import Foundation

/// Code chunk with embedding for RAG/vector search
/// Following Single Responsibility Principle - represents code chunk
public struct CodeChunk: Identifiable, Sendable {
    public let id: UUID
    public let fileId: UUID
    public let codebaseId: UUID
    public let projectId: UUID
    public let filePath: String
    public let content: String
    public let contentHash: String
    public let startLine: Int
    public let endLine: Int
    public let chunkType: ChunkType
    public let language: ProgrammingLanguage
    public let symbols: [String]
    public let imports: [String]
    public let tokenCount: Int
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        fileId: UUID,
        codebaseId: UUID,
        projectId: UUID,
        filePath: String,
        content: String,
        contentHash: String,
        startLine: Int,
        endLine: Int,
        chunkType: ChunkType,
        language: ProgrammingLanguage,
        symbols: [String] = [],
        imports: [String] = [],
        tokenCount: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fileId = fileId
        self.codebaseId = codebaseId
        self.projectId = projectId
        self.filePath = filePath
        self.content = content
        self.contentHash = contentHash
        self.startLine = startLine
        self.endLine = endLine
        self.chunkType = chunkType
        self.language = language
        self.symbols = symbols
        self.imports = imports
        self.tokenCount = tokenCount
        self.createdAt = createdAt
    }
}

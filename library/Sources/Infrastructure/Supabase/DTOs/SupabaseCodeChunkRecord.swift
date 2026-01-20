import Foundation

/// Supabase Code Chunk Record
/// Maps to code_chunks table schema (000_complete_schema.sql)
/// Backend compatibility layer (ONLY exception per Rule 8)
public struct SupabaseCodeChunkRecord: Codable, Sendable {
    let id: String
    let fileId: String
    let codebaseId: String
    let projectId: String
    let filePath: String
    let content: String
    let contentHash: String
    let startLine: Int
    let endLine: Int
    let chunkType: String
    let language: String
    let symbols: [String]
    let imports: [String]
    let tokenCount: Int
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case fileId = "file_id"
        case codebaseId = "codebase_id"
        case projectId = "project_id"
        case filePath = "file_path"
        case content
        case contentHash = "content_hash"
        case startLine = "start_line"
        case endLine = "end_line"
        case chunkType = "chunk_type"
        case language
        case symbols
        case imports
        case tokenCount = "token_count"
        case createdAt = "created_at"
    }

    /// Initializer for creating records to insert
    public init(
        id: String,
        fileId: String,
        codebaseId: String,
        projectId: String,
        filePath: String,
        content: String,
        contentHash: String,
        startLine: Int,
        endLine: Int,
        chunkType: String,
        language: String,
        symbols: [String],
        imports: [String],
        tokenCount: Int,
        createdAt: String
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

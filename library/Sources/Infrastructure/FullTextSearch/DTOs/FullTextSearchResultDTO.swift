import AIPRDSharedUtilities
import Foundation

/// DTO for full-text search results from PostgreSQL
/// Maps database response to domain FullTextSearchResult
struct FullTextSearchResultDTO: Codable, Sendable {
    let chunkId: String
    let fileId: String
    let codebaseId: String
    let projectId: String
    let filePath: String
    let content: String
    let contentHash: String
    let startLine: Int
    let endLine: Int
    let language: String
    let chunkType: String
    let symbols: [String]
    let imports: [String]
    let tokenCount: Int
    let createdAt: String
    let bm25Score: Float

    enum CodingKeys: String, CodingKey {
        case chunkId = "chunk_id"
        case fileId = "file_id"
        case codebaseId = "codebase_id"
        case projectId = "project_id"
        case filePath = "file_path"
        case content
        case contentHash = "content_hash"
        case startLine = "start_line"
        case endLine = "end_line"
        case language
        case chunkType = "chunk_type"
        case symbols
        case imports
        case tokenCount = "token_count"
        case createdAt = "created_at"
        case bm25Score = "bm25_score"
    }

    func toDomain(rank: Int) throws -> FullTextSearchResult {
        guard let chunkUUID = UUID(uuidString: chunkId),
              let fileUUID = UUID(uuidString: fileId),
              let codebaseUUID = UUID(uuidString: codebaseId),
              let projectUUID = UUID(uuidString: projectId) else {
            throw MappingError.invalidUUID
        }

        guard let lang = ProgrammingLanguage(rawValue: language) else {
            throw MappingError.invalidLanguage(language)
        }

        guard let type = ChunkType(rawValue: chunkType) else {
            throw MappingError.invalidChunkType(chunkType)
        }

        // Parse ISO8601 timestamp
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.date(from: createdAt) ?? Date()

        let chunk = CodeChunk(
            id: chunkUUID,
            fileId: fileUUID,
            codebaseId: codebaseUUID,
            projectId: projectUUID,
            filePath: filePath,
            content: content,
            contentHash: contentHash,
            startLine: startLine,
            endLine: endLine,
            chunkType: type,
            language: lang,
            symbols: symbols,
            imports: imports,
            tokenCount: tokenCount,
            createdAt: timestamp
        )

        return FullTextSearchResult(
            chunk: chunk,
            bm25Score: bm25Score,
            rank: rank
        )
    }
}

import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Extension for CodeChunk mapping
/// Single Responsibility: Map CodeChunk and SimilarCodeChunk between database and domain
extension PostgreSQLCodebaseMapper {
    // MARK: - CodeChunk Mapping

    public func chunkToDomain(_ row: [String: Any]) throws -> CodeChunk {
        guard let id = row["id"] as? String,
              let codebaseId = row["codebase_id"] as? String,
              let projectId = row["project_id"] as? String,
              let fileId = row["file_id"] as? String,
              let filePath = row["file_path"] as? String,
              let content = row["content"] as? String,
              let startLine = row["start_line"] as? Int,
              let endLine = row["end_line"] as? Int,
              let contentHash = row["content_hash"] as? String,
              let createdAt = row["created_at"] as? String else {
            throw PostgreSQLError.missingRequiredColumn("chunk mapping")
        }

        let chunkTypeStr = row["chunk_type"] as? String ?? "other"
        let chunkType = ChunkType(rawValue: chunkTypeStr) ?? .other

        let languageStr = row["language"] as? String ?? "unknown"
        let language = ProgrammingLanguage(rawValue: languageStr) ?? .unknown

        let enrichedContent = row["enriched_content"] as? String  // Optional - null if not enriched

        return CodeChunk(
            id: UUID(uuidString: id) ?? UUID(),
            fileId: UUID(uuidString: fileId) ?? UUID(),
            codebaseId: UUID(uuidString: codebaseId) ?? UUID(),
            projectId: UUID(uuidString: projectId) ?? UUID(),
            filePath: filePath,
            content: content,
            enrichedContent: enrichedContent,
            contentHash: contentHash,
            startLine: startLine,
            endLine: endLine,
            chunkType: chunkType,
            language: language,
            symbols: row["symbols"] as? [String] ?? [],
            imports: row["imports"] as? [String] ?? [],
            tokenCount: row["token_count"] as? Int ?? 0,
            createdAt: parseISO8601Date(createdAt) ?? Date()
        )
    }

    public func chunkToDict(_ domain: CodeChunk) -> [String: Any] {
        var dict: [String: Any] = [
            "id": domain.id.uuidString,
            "codebase_id": domain.codebaseId.uuidString,
            "project_id": domain.projectId.uuidString,
            "file_id": domain.fileId.uuidString,
            "file_path": domain.filePath,
            "content": domain.content,
            "start_line": domain.startLine,
            "end_line": domain.endLine,
            "chunk_type": domain.chunkType.rawValue,
            "language": domain.language.rawValue,
            "symbols": domain.symbols,
            "imports": domain.imports,
            "token_count": domain.tokenCount,
            "content_hash": domain.contentHash,
            "created_at": formatISO8601Date(domain.createdAt)
        ]

        // Add enriched_content if available (nullable in DB)
        if let enrichedContent = domain.enrichedContent {
            dict["enriched_content"] = enrichedContent
        }

        return dict
    }

    // MARK: - SimilarCodeChunk Mapping

    public func similarChunkToDomain(_ row: [String: Any]) throws -> SimilarCodeChunk {
        // Extract chunk JSON from RPC result
        guard let chunkData = row["chunk"] as? [String: Any],
              let similarity = row["similarity"] as? Double else {
            throw PostgreSQLError.missingRequiredColumn("similar chunk mapping")
        }

        let chunk = try chunkToDomain(chunkData)
        return SimilarCodeChunk(chunk: chunk, similarity: similarity)
    }
}

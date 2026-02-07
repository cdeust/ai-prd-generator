import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Extension for code chunk operations
/// Single Responsibility: Code chunk persistence
extension PostgreSQLCodebaseRepository {
    // MARK: - Code Chunk Operations

    public func saveChunks(_ chunks: [CodeChunk], projectId: UUID) async throws -> [CodeChunk] {
        let dicts = chunks.map { mapper.chunkToDict($0) }
        let data = try await databaseClient.insertBatch(table: "code_chunks", values: dicts)
        let rows = try decodeRows(from: data)
        return try rows.map { try mapper.chunkToDomain($0) }
    }

    public func findChunksByProject(
        _ projectId: UUID,
        limit: Int,
        offset: Int
    ) async throws -> [CodeChunk] {
        let sql = """
        SELECT * FROM code_chunks
        WHERE project_id = $1
        ORDER BY file_path, chunk_index
        LIMIT $2 OFFSET $3;
        """
        let rows = try await databaseClient.executeQuery(
            sql,
            parameters: [projectId.uuidString, limit, offset]
        )
        return try rows.map { try mapper.chunkToDomain($0) }
    }

    public func findChunksByFile(_ fileId: UUID) async throws -> [CodeChunk] {
        let data = try await databaseClient.select(
            from: "code_chunks",
            columns: nil,
            whereClause: "file_id = $1",
            parameters: [fileId.uuidString]
        )
        let rows = try decodeRows(from: data)
        return try rows.map { try mapper.chunkToDomain($0) }
    }

    public func findChunksInFile(
        codebaseId: UUID,
        filePath: String,
        endLineBefore: Int?,
        startLineAfter: Int?,
        limit: Int
    ) async throws -> [CodeChunk] {
        // Use optimized RPC functions for database-level filtering
        if let endBefore = endLineBefore, startLineAfter == nil {
            // Find chunks BEFORE a line
            return try await findChunksBefore(
                codebaseId: codebaseId,
                filePath: filePath,
                endLineBefore: endBefore,
                limit: limit
            )
        } else if let startAfter = startLineAfter, endLineBefore == nil {
            // Find chunks AFTER a line
            return try await findChunksAfter(
                codebaseId: codebaseId,
                filePath: filePath,
                startLineAfter: startAfter,
                limit: limit
            )
        } else {
            // Should not happen with current ChunkExpander usage
            throw RepositoryError.invalidQuery("Cannot specify both endLineBefore and startLineAfter")
        }
    }

    private func findChunksBefore(
        codebaseId: UUID,
        filePath: String,
        endLineBefore: Int,
        limit: Int
    ) async throws -> [CodeChunk] {
        let params: [String: Any] = [
            "p_codebase_id": codebaseId.uuidString,
            "p_file_path": filePath,
            "p_end_line_before": endLineBefore,
            "p_limit": limit
        ]

        let data = try await databaseClient.callRPC(
            function: "find_chunks_before_line",
            parameters: params
        )

        let rows = try decodeRows(from: data)
        return try rows.map { try mapper.chunkToDomain($0) }
    }

    private func findChunksAfter(
        codebaseId: UUID,
        filePath: String,
        startLineAfter: Int,
        limit: Int
    ) async throws -> [CodeChunk] {
        let params: [String: Any] = [
            "p_codebase_id": codebaseId.uuidString,
            "p_file_path": filePath,
            "p_start_line_after": startLineAfter,
            "p_limit": limit
        ]

        let data = try await databaseClient.callRPC(
            function: "find_chunks_after_line",
            parameters: params
        )

        let rows = try decodeRows(from: data)
        return try rows.map { try mapper.chunkToDomain($0) }
    }

    public func deleteChunksByProject(_ projectId: UUID) async throws {
        try await databaseClient.delete(
            from: "code_chunks",
            whereClause: "project_id = $1",
            parameters: [projectId.uuidString]
        )
    }
}

import Foundation
import Domain

/// Supabase-based vector search implementation using pgvector
/// Single Responsibility: Vector similarity search via Supabase RPC functions
/// Implements VectorSearchPort for semantic code search
public final class SupabaseVectorSearch: VectorSearchPort, Sendable {
    // MARK: - Properties

    private let databaseClient: SupabaseDatabasePort
    private let mapper: SupabaseCodebaseMapper

    // MARK: - Initialization

    public init(
        databaseClient: SupabaseDatabasePort,
        mapper: SupabaseCodebaseMapper
    ) {
        self.databaseClient = databaseClient
        self.mapper = mapper
    }

    // MARK: - VectorSearchPort Implementation

    public func searchSimilarChunks(
        in codebaseId: UUID,
        queryEmbedding: [Float],
        limit: Int,
        similarityThreshold: Float
    ) async throws -> [VectorSearchResult] {
        let parameters = buildChunkSearchParameters(
            codebaseId: codebaseId,
            embedding: queryEmbedding,
            limit: limit,
            threshold: similarityThreshold
        )

        let data = try await databaseClient.callRPC(
            function: "match_code_chunks",
            parameters: parameters
        )

        let dtoResults = try decodeSearchResults(from: data)
        return try await mapToVectorSearchResults(dtoResults, codebaseId: codebaseId)
    }

    public func searchSimilarFiles(
        in codebaseId: UUID,
        queryEmbedding: [Float],
        limit: Int
    ) async throws -> [(file: CodeFile, similarity: Float)] {
        let parameters = buildFileSearchParameters(
            codebaseId: codebaseId,
            embedding: queryEmbedding,
            limit: limit
        )

        let data = try await databaseClient.callRPC(
            function: "match_code_files",
            parameters: parameters
        )

        let results = try decodeFileSearchResults(from: data)
        return mapToFileResults(results)
    }

    // MARK: - Private Methods

    private func buildChunkSearchParameters(
        codebaseId: UUID,
        embedding: [Float],
        limit: Int,
        threshold: Float
    ) -> [String: Any] {
        [
            "project_id": codebaseId.uuidString,
            "query_embedding": embedding,
            "match_threshold": threshold,
            "match_count": limit
        ]
    }

    private func buildFileSearchParameters(
        codebaseId: UUID,
        embedding: [Float],
        limit: Int
    ) -> [String: Any] {
        [
            "codebase_id": codebaseId.uuidString,
            "query_embedding": embedding,
            "match_threshold": 0.7,
            "match_count": limit
        ]
    }

    private func decodeSearchResults(
        from data: Data
    ) throws -> [SupabaseVectorSearchResult] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([SupabaseVectorSearchResult].self, from: data)
    }

    private func decodeFileSearchResults(
        from data: Data
    ) throws -> [FileVectorSearchResult] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([FileVectorSearchResult].self, from: data)
    }

    private func mapToVectorSearchResults(
        _ dtoResults: [SupabaseVectorSearchResult],
        codebaseId: UUID
    ) async throws -> [VectorSearchResult] {
        guard !dtoResults.isEmpty else { return [] }

        // Convert all chunks to domain entities
        let chunks = dtoResults.map { mapper.chunkToDomain($0.chunk) }

        // Batch fetch all files in one query
        let fileIds = Set(chunks.map { $0.fileId })
        let files = try await batchFetchFiles(fileIds: Array(fileIds))

        // Create lookup map for O(1) access
        let fileMap = Dictionary(uniqueKeysWithValues: files.map { ($0.id, $0) })

        // Map results with pre-fetched files
        var results: [VectorSearchResult] = []
        for (index, dtoResult) in dtoResults.enumerated() {
            let chunk = mapper.chunkToDomain(dtoResult.chunk)

            guard let file = fileMap[chunk.fileId] else {
                continue // Skip if file not found
            }

            results.append(VectorSearchResult(
                chunk: chunk,
                file: file,
                similarity: Float(dtoResult.similarity),
                rank: index + 1
            ))
        }

        return results
    }

    private func batchFetchFiles(fileIds: [UUID]) async throws -> [CodeFile] {
        guard !fileIds.isEmpty else { return [] }

        // Build IN clause filter for batch fetch
        let filter = QueryFilter(
            field: "id",
            operation: .in,
            value: fileIds.map { $0.uuidString }
        )

        let fileData = try await databaseClient.select(
            from: "code_files",
            columns: nil,
            filter: filter
        )

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let fileRecords = try decoder.decode(
            [SupabaseCodeFileRecord].self,
            from: fileData
        )

        return fileRecords.map { mapper.fileToDomain($0) }
    }

    private func mapToFileResults(
        _ results: [FileVectorSearchResult]
    ) -> [(file: CodeFile, similarity: Float)] {
        results.map { result in
            (
                file: mapper.fileToDomain(result.file),
                similarity: result.similarity
            )
        }
    }
}


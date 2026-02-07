import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// PostgreSQL full-text search implementation for standalone skill
/// Implements database-level BM25 ranking for scalability
/// Following Interface Segregation Principle: depends only on database operations
public struct PostgreSQLFullTextSearch: FullTextSearchPort, Sendable {
    private let databaseClient: PostgreSQLDatabasePort
    private let chunkTableName = "code_chunks"
    private let fileTableName = "code_files"

    public init(databaseClient: PostgreSQLDatabasePort) {
        self.databaseClient = databaseClient
    }

    public func searchChunks(
        in codebaseId: UUID,
        query: String,
        limit: Int,
        minScore: Float
    ) async throws -> [FullTextSearchResult] {
        let results = try await performChunkSearch(
            codebaseId: codebaseId,
            query: query,
            limit: limit,
            minScore: minScore
        )

        return try await mapToFullTextResults(results)
    }

    public func searchFiles(
        in codebaseId: UUID,
        query: String,
        limit: Int
    ) async throws -> [(file: CodeFile, bm25Score: Float)] {
        let results = try await performFileSearch(
            codebaseId: codebaseId,
            query: query,
            limit: limit
        )

        return try await mapToFileResults(results)
    }

    // MARK: - Private Methods

    private func performChunkSearch(
        codebaseId: UUID,
        query: String,
        limit: Int,
        minScore: Float
    ) async throws -> [FullTextSearchResultDTO] {
        let rpcFunction = "search_code_chunks_fulltext"

        let parameters: [String: Any] = [
            "codebase_id": codebaseId.uuidString,
            "search_query": query,
            "result_limit": limit,
            "min_score": minScore
        ]

        return try await databaseClient.callRPC(
            function: rpcFunction,
            parameters: parameters
        )
    }

    private func performFileSearch(
        codebaseId: UUID,
        query: String,
        limit: Int
    ) async throws -> [FileFullTextSearchResultDTO] {
        let rpcFunction = "search_code_files_fulltext"

        let parameters: [String: Any] = [
            "codebase_id": codebaseId.uuidString,
            "search_query": query,
            "result_limit": limit
        ]

        return try await databaseClient.callRPC(
            function: rpcFunction,
            parameters: parameters
        )
    }

    private func mapToFullTextResults(
        _ dtos: [FullTextSearchResultDTO]
    ) async throws -> [FullTextSearchResult] {
        try await withThrowingTaskGroup(
            of: FullTextSearchResult?.self
        ) { group in
            for (index, dto) in dtos.enumerated() {
                group.addTask {
                    try dto.toDomain(rank: index + 1)
                }
            }

            var results: [FullTextSearchResult] = []
            for try await result in group {
                if let result = result {
                    results.append(result)
                }
            }

            return results.sorted { $0.rank < $1.rank }
        }
    }

    private func mapToFileResults(
        _ dtos: [FileFullTextSearchResultDTO]
    ) async throws -> [(file: CodeFile, bm25Score: Float)] {
        try await withThrowingTaskGroup(
            of: (file: CodeFile, bm25Score: Float)?.self
        ) { group in
            for dto in dtos {
                group.addTask {
                    try dto.toFileTuple()
                }
            }

            var results: [(file: CodeFile, bm25Score: Float)] = []
            for try await result in group {
                if let result = result {
                    results.append(result)
                }
            }

            return results.sorted { $0.bm25Score > $1.bm25Score }
        }
    }
}

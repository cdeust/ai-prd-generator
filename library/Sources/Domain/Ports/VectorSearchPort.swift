import Foundation

/// Port for vector similarity search (Supabase pgvector)
/// Domain defines the interface, Infrastructure implements with Supabase
public protocol VectorSearchPort: Sendable {
    /// Search for similar code chunks using vector similarity
    /// - Parameters:
    ///   - codebaseId: Codebase to search in
    ///   - queryEmbedding: Query vector
    ///   - limit: Maximum results
    ///   - similarityThreshold: Minimum similarity score (0.0-1.0)
    /// - Returns: Ranked search results
    func searchSimilarChunks(
        in codebaseId: UUID,
        queryEmbedding: [Float],
        limit: Int,
        similarityThreshold: Float
    ) async throws -> [VectorSearchResult]

    /// Search files by semantic similarity
    /// - Parameters:
    ///   - codebaseId: Codebase to search
    ///   - queryEmbedding: Query vector
    ///   - limit: Maximum results
    /// - Returns: Relevant files with similarity scores
    func searchSimilarFiles(
        in codebaseId: UUID,
        queryEmbedding: [Float],
        limit: Int
    ) async throws -> [(file: CodeFile, similarity: Float)]
}

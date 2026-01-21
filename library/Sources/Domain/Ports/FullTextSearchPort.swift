import Foundation

/// Port for database-level full-text search (PostgreSQL, BM25, etc.)
/// Domain defines the interface, Infrastructure implements with PostgreSQL
public protocol FullTextSearchPort: Sendable {
    /// Search for code chunks using full-text search with BM25 ranking
    /// - Parameters:
    ///   - codebaseId: Codebase to search in
    ///   - query: Search query string
    ///   - limit: Maximum results to return
    ///   - minScore: Minimum relevance score threshold
    /// - Returns: Ranked search results with BM25 scores
    func searchChunks(
        in codebaseId: UUID,
        query: String,
        limit: Int,
        minScore: Float
    ) async throws -> [FullTextSearchResult]

    /// Search for files using full-text search
    /// - Parameters:
    ///   - codebaseId: Codebase to search in
    ///   - query: Search query string
    ///   - limit: Maximum results to return
    /// - Returns: Relevant files with BM25 scores
    func searchFiles(
        in codebaseId: UUID,
        query: String,
        limit: Int
    ) async throws -> [(file: CodeFile, bm25Score: Float)]
}

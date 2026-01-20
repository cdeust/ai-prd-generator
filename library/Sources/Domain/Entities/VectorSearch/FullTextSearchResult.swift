import Foundation

/// Result from full-text search with BM25 ranking
/// Domain entity for database-level keyword search results
public struct FullTextSearchResult: Identifiable, Sendable {
    public let id: UUID
    public let chunk: CodeChunk
    public let bm25Score: Float
    public let rank: Int

    public init(
        id: UUID = UUID(),
        chunk: CodeChunk,
        bm25Score: Float,
        rank: Int
    ) {
        self.id = id
        self.chunk = chunk
        self.bm25Score = bm25Score
        self.rank = rank
    }
}

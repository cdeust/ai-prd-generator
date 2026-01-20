import Foundation
import Domain

/// Hybrid search result combining vector and keyword signals
/// Following Single Responsibility: Represents hybrid search outcome
public struct HybridSearchResult: Sendable {
    public let chunk: CodeChunk
    public let vectorSimilarity: Double?
    public let bm25Score: Double?
    public let hybridScore: Double

    public init(
        chunk: CodeChunk,
        vectorSimilarity: Double?,
        bm25Score: Double?,
        hybridScore: Double
    ) {
        self.chunk = chunk
        self.vectorSimilarity = vectorSimilarity
        self.bm25Score = bm25Score
        self.hybridScore = hybridScore
    }
}

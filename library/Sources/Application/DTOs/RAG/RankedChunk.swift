import Foundation
import Domain

/// Reranked chunk with combined scoring
/// Following Single Responsibility: Represents reranked search result
public struct RankedChunk: Sendable {
    public let chunk: CodeChunk
    public let originalSimilarity: Double
    public let rerankScore: Double
    public let finalScore: Double

    public init(
        chunk: CodeChunk,
        originalSimilarity: Double,
        rerankScore: Double,
        finalScore: Double
    ) {
        self.chunk = chunk
        self.originalSimilarity = originalSimilarity
        self.rerankScore = rerankScore
        self.finalScore = finalScore
    }
}

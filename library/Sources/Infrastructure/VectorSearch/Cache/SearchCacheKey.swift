import AIPRDSharedUtilities
import Foundation

/// Cache key for vector search results
/// Extracted per Rule 9 (no nested types)
public struct SearchCacheKey: Hashable, Sendable {
    public let codebaseId: UUID
    public let queryHash: String
    public let limit: Int
    public let threshold: Float

    public init(
        codebaseId: UUID,
        queryEmbedding: [Float],
        limit: Int,
        threshold: Float
    ) {
        self.codebaseId = codebaseId
        self.queryHash = Self.hashEmbedding(queryEmbedding)
        self.limit = limit
        self.threshold = threshold
    }

    private static func hashEmbedding(_ embedding: [Float]) -> String {
        let rounded = embedding.prefix(20).map { round($0 * 1000) / 1000 }
        return rounded.map { String(format: "%.3f", $0) }.joined(separator: ",")
    }
}

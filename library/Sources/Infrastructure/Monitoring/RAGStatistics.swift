import AIPRDSharedUtilities
import Foundation

/// Aggregated RAG performance statistics
/// Extracted per Rule 9 (no nested types)
public struct RAGStatistics: Sendable {
    public let totalSearches: Int
    public let totalRetrievals: Int
    public let averageSearchLatency: TimeInterval
    public let averageRetrievalLatency: TimeInterval
    public let cacheHitRate: Double
    public let averageResultCount: Double
    public let averageContextSize: Double
    public let p95SearchLatency: TimeInterval
    public let p99SearchLatency: TimeInterval

    public init(
        totalSearches: Int,
        totalRetrievals: Int,
        averageSearchLatency: TimeInterval,
        averageRetrievalLatency: TimeInterval,
        cacheHitRate: Double,
        averageResultCount: Double,
        averageContextSize: Double,
        p95SearchLatency: TimeInterval,
        p99SearchLatency: TimeInterval
    ) {
        self.totalSearches = totalSearches
        self.totalRetrievals = totalRetrievals
        self.averageSearchLatency = averageSearchLatency
        self.averageRetrievalLatency = averageRetrievalLatency
        self.cacheHitRate = cacheHitRate
        self.averageResultCount = averageResultCount
        self.averageContextSize = averageContextSize
        self.p95SearchLatency = p95SearchLatency
        self.p99SearchLatency = p99SearchLatency
    }

    public var isPerformant: Bool {
        averageSearchLatency < 0.1 && p95SearchLatency < 0.5 && cacheHitRate > 0.3
    }
}

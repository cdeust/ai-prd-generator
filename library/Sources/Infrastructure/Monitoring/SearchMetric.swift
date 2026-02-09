import AIPRDSharedUtilities
import Foundation

/// Metric for a single search operation
/// Extracted per Rule 9 (no nested types)
public struct SearchMetric: Sendable {
    public let timestamp: Date
    public let queryHash: String
    public let latency: TimeInterval
    public let resultCount: Int
    public let cacheHit: Bool

    public init(
        timestamp: Date = Date(),
        queryHash: String,
        latency: TimeInterval,
        resultCount: Int,
        cacheHit: Bool
    ) {
        self.timestamp = timestamp
        self.queryHash = queryHash
        self.latency = latency
        self.resultCount = resultCount
        self.cacheHit = cacheHit
    }
}

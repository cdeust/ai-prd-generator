import AIPRDSharedUtilities
import Foundation

/// Aggregated statistics for search operations
/// Extracted per Rule 9 (no nested types)
struct AggregatedSearchStats: Sendable {
    let averageLatency: TimeInterval
    let p95Latency: TimeInterval
    let p99Latency: TimeInterval
    let cacheHitRate: Double
    let averageResultCount: Double

    static var empty: AggregatedSearchStats {
        AggregatedSearchStats(
            averageLatency: 0,
            p95Latency: 0,
            p99Latency: 0,
            cacheHitRate: 0,
            averageResultCount: 0
        )
    }
}

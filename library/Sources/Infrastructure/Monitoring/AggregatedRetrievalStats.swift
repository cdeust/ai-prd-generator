import AIPRDSharedUtilities
import Foundation

/// Aggregated statistics for retrieval operations
/// Extracted per Rule 9 (no nested types)
struct AggregatedRetrievalStats: Sendable {
    let averageLatency: TimeInterval
    let averageContextSize: Double

    static var empty: AggregatedRetrievalStats {
        AggregatedRetrievalStats(
            averageLatency: 0,
            averageContextSize: 0
        )
    }
}

import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Collects and tracks RAG retrieval metrics for monitoring
/// Following Single Responsibility: Only handles metrics collection
public actor RAGMetricsCollector {
    private var searchMetrics: [SearchMetric] = []
    private var retrievalMetrics: [RetrievalMetric] = []
    private let maxStoredMetrics: Int

    public init(maxStoredMetrics: Int = 10_000) {
        self.maxStoredMetrics = maxStoredMetrics
    }

    /// Record a search operation
    public func recordSearch(
        _ metric: SearchMetric
    ) {
        searchMetrics.append(metric)
        evictOldestIfNeeded()
    }

    /// Record a retrieval operation
    public func recordRetrieval(
        _ metric: RetrievalMetric
    ) {
        retrievalMetrics.append(metric)
        evictOldestIfNeeded()
    }

    /// Get aggregated statistics
    public func getStatistics() -> RAGStatistics {
        let searchStats = aggregateSearchMetrics()
        let retrievalStats = aggregateRetrievalMetrics()

        return RAGStatistics(
            totalSearches: searchMetrics.count,
            totalRetrievals: retrievalMetrics.count,
            averageSearchLatency: searchStats.averageLatency,
            averageRetrievalLatency: retrievalStats.averageLatency,
            cacheHitRate: searchStats.cacheHitRate,
            averageResultCount: searchStats.averageResultCount,
            averageContextSize: retrievalStats.averageContextSize,
            p95SearchLatency: searchStats.p95Latency,
            p99SearchLatency: searchStats.p99Latency
        )
    }

    /// Clear all collected metrics
    public func clear() {
        searchMetrics.removeAll()
        retrievalMetrics.removeAll()
    }

    // MARK: - Private Methods

    private func evictOldestIfNeeded() {
        let totalMetrics = searchMetrics.count + retrievalMetrics.count

        guard totalMetrics > maxStoredMetrics else { return }

        let toRemove = totalMetrics - maxStoredMetrics
        let searchToRemove = min(toRemove, searchMetrics.count)
        let retrievalToRemove = toRemove - searchToRemove

        if searchToRemove > 0 {
            searchMetrics.removeFirst(searchToRemove)
        }

        if retrievalToRemove > 0 {
            retrievalMetrics.removeFirst(retrievalToRemove)
        }
    }

    private func aggregateSearchMetrics() -> AggregatedSearchStats {
        guard !searchMetrics.isEmpty else {
            return AggregatedSearchStats.empty
        }

        let latencies = searchMetrics.map { $0.latency }
        let sortedLatencies = latencies.sorted()

        let cacheHits = searchMetrics.filter { $0.cacheHit }.count
        let resultCounts = searchMetrics.map { Double($0.resultCount) }

        return AggregatedSearchStats(
            averageLatency: latencies.reduce(0, +) / Double(latencies.count),
            p95Latency: percentile(sortedLatencies, 0.95),
            p99Latency: percentile(sortedLatencies, 0.99),
            cacheHitRate: Double(cacheHits) / Double(searchMetrics.count),
            averageResultCount: resultCounts.reduce(0, +) / Double(resultCounts.count)
        )
    }

    private func aggregateRetrievalMetrics() -> AggregatedRetrievalStats {
        guard !retrievalMetrics.isEmpty else {
            return AggregatedRetrievalStats.empty
        }

        let latencies = retrievalMetrics.map { $0.latency }
        let contextSizes = retrievalMetrics.map { Double($0.contextSize) }

        return AggregatedRetrievalStats(
            averageLatency: latencies.reduce(0, +) / Double(latencies.count),
            averageContextSize: contextSizes.reduce(0, +) / Double(contextSizes.count)
        )
    }

    private func percentile(_ sorted: [TimeInterval], _ p: Double) -> TimeInterval {
        guard !sorted.isEmpty else { return 0 }

        let index = Int(Double(sorted.count) * p)
        let safeIndex = min(index, sorted.count - 1)

        return sorted[safeIndex]
    }
}

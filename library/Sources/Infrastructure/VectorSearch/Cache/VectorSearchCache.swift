import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// In-memory cache for vector search results with TTL and size limits
/// Following Single Responsibility: Only handles search result caching
public actor VectorSearchCache {
    private var cache: [SearchCacheKey: SearchCacheEntry] = [:]
    private let maxEntries: Int
    private let defaultTTL: TimeInterval

    public init(
        maxEntries: Int = 1000,
        defaultTTL: TimeInterval = 300
    ) {
        self.maxEntries = maxEntries
        self.defaultTTL = defaultTTL
    }

    /// Get cached results if available and not expired
    public func get(for key: SearchCacheKey) -> [VectorSearchResult]? {
        guard let entry = cache[key], !entry.isExpired else {
            if let entry = cache[key], entry.isExpired {
                cache.removeValue(forKey: key)
            }
            return nil
        }

        return entry.results
    }

    /// Store results in cache with eviction if needed
    public func set(
        _ results: [VectorSearchResult],
        for key: SearchCacheKey,
        ttl: TimeInterval? = nil
    ) {
        evictIfNeeded()

        let entry = SearchCacheEntry(
            results: results,
            ttl: ttl ?? defaultTTL
        )

        cache[key] = entry
    }

    /// Clear all cache entries
    public func clear() {
        cache.removeAll()
    }

    /// Remove expired entries
    public func removeExpired() {
        let expiredKeys = cache.filter { $0.value.isExpired }.map { $0.key }
        expiredKeys.forEach { cache.removeValue(forKey: $0) }
    }

    /// Get cache statistics
    public func getStats() -> CacheStats {
        let totalEntries = cache.count
        let expiredEntries = cache.values.filter { $0.isExpired }.count
        let averageAge = cache.values.map { $0.age }.reduce(0, +) / Double(max(totalEntries, 1))

        return CacheStats(
            totalEntries: totalEntries,
            expiredEntries: expiredEntries,
            activeEntries: totalEntries - expiredEntries,
            averageAge: averageAge,
            maxEntries: maxEntries,
            utilizationPercent: (Double(totalEntries) / Double(maxEntries)) * 100
        )
    }

    // MARK: - Private Methods

    private func evictIfNeeded() {
        guard cache.count >= maxEntries else { return }

        removeExpired()

        if cache.count >= maxEntries {
            evictOldest()
        }
    }

    private func evictOldest() {
        guard let oldestKey = cache
            .min(by: { $0.value.timestamp < $1.value.timestamp })?
            .key else { return }

        cache.removeValue(forKey: oldestKey)
    }
}

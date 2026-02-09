import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Cache entry for vector search results with TTL
/// Extracted per Rule 9 (no nested types)
public struct SearchCacheEntry: Sendable {
    public let results: [VectorSearchResult]
    public let timestamp: Date
    public let ttl: TimeInterval

    public init(
        results: [VectorSearchResult],
        timestamp: Date = Date(),
        ttl: TimeInterval = 300 // 5 minutes default
    ) {
        self.results = results
        self.timestamp = timestamp
        self.ttl = ttl
    }

    public var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > ttl
    }

    public var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
}

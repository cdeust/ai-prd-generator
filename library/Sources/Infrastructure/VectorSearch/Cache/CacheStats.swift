import AIPRDSharedUtilities
import Foundation

/// Statistics for cache monitoring and observability
/// Extracted per Rule 9 (no nested types)
public struct CacheStats: Sendable {
    public let totalEntries: Int
    public let expiredEntries: Int
    public let activeEntries: Int
    public let averageAge: TimeInterval
    public let maxEntries: Int
    public let utilizationPercent: Double

    public init(
        totalEntries: Int,
        expiredEntries: Int,
        activeEntries: Int,
        averageAge: TimeInterval,
        maxEntries: Int,
        utilizationPercent: Double
    ) {
        self.totalEntries = totalEntries
        self.expiredEntries = expiredEntries
        self.activeEntries = activeEntries
        self.averageAge = averageAge
        self.maxEntries = maxEntries
        self.utilizationPercent = utilizationPercent
    }

    public var isHealthy: Bool {
        utilizationPercent < 90 && (Double(expiredEntries) / Double(max(totalEntries, 1))) < 0.3
    }
}

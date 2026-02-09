import AIPRDSharedUtilities
import Foundation

/// Metric for a single retrieval operation
/// Extracted per Rule 9 (no nested types)
public struct RetrievalMetric: Sendable {
    public let timestamp: Date
    public let queryId: UUID
    public let latency: TimeInterval
    public let contextSize: Int
    public let stagesExecuted: Int

    public init(
        timestamp: Date = Date(),
        queryId: UUID,
        latency: TimeInterval,
        contextSize: Int,
        stagesExecuted: Int
    ) {
        self.timestamp = timestamp
        self.queryId = queryId
        self.latency = latency
        self.contextSize = contextSize
        self.stagesExecuted = stagesExecuted
    }
}

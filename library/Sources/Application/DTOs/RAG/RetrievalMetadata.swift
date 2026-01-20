import Foundation

/// Metadata about retrieval pipeline stages
/// Following Single Responsibility: Tracks retrieval metrics
public struct RetrievalMetadata: Sendable {
    public let queriesUsed: [String]
    public let totalCandidates: Int
    public let afterDeduplication: Int
    public let afterContextFilter: Int
    public let afterReranking: Int
    public let finalSelected: Int

    public init(
        queriesUsed: [String],
        totalCandidates: Int,
        afterDeduplication: Int,
        afterContextFilter: Int,
        afterReranking: Int,
        finalSelected: Int
    ) {
        self.queriesUsed = queriesUsed
        self.totalCandidates = totalCandidates
        self.afterDeduplication = afterDeduplication
        self.afterContextFilter = afterContextFilter
        self.afterReranking = afterReranking
        self.finalSelected = finalSelected
    }
}

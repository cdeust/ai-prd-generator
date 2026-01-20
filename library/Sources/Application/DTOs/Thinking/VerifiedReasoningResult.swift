import Foundation
import Domain

/// Result of verified reasoning execution with quality metrics
/// Following Single Responsibility: Represents reasoning outcome with reliability assessment
public struct VerifiedReasoningResult: Sendable {
    public let problem: String
    public let conclusion: String
    public let confidence: Double
    public let reliabilityScore: Double
    public let verifiedChain: VerifiedThoughtChain
    public let retrievalMetadata: RetrievalMetadata?
    public let iterationsNeeded: Int
    public let qualityMetrics: QualityMetrics

    public init(
        problem: String,
        conclusion: String,
        confidence: Double,
        reliabilityScore: Double,
        verifiedChain: VerifiedThoughtChain,
        retrievalMetadata: RetrievalMetadata?,
        iterationsNeeded: Int,
        qualityMetrics: QualityMetrics
    ) {
        self.problem = problem
        self.conclusion = conclusion
        self.confidence = confidence
        self.reliabilityScore = reliabilityScore
        self.verifiedChain = verifiedChain
        self.retrievalMetadata = retrievalMetadata
        self.iterationsNeeded = iterationsNeeded
        self.qualityMetrics = qualityMetrics
    }
}

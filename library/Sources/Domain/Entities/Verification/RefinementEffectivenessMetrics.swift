import Foundation

/// Refinement effectiveness metrics
public struct RefinementEffectivenessMetrics: Sendable, Codable {
    public let entityType: VerificationEntityType
    public let totalRefinements: Int
    public let averageScoreImprovement: Double
    public let successRate: Double // % where score improved
    public let refinementsByAttempt: [Int: RefinementAttemptMetrics]

    public init(
        entityType: VerificationEntityType,
        totalRefinements: Int,
        averageScoreImprovement: Double,
        successRate: Double,
        refinementsByAttempt: [Int: RefinementAttemptMetrics]
    ) {
        self.entityType = entityType
        self.totalRefinements = totalRefinements
        self.averageScoreImprovement = averageScoreImprovement
        self.successRate = successRate
        self.refinementsByAttempt = refinementsByAttempt
    }

    /// Whether refinement is generally effective
    public var refinementIsEffective: Bool {
        successRate > 0.7 && averageScoreImprovement > 0.05
    }
}

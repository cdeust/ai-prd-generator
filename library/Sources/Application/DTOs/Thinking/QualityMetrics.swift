import Foundation

/// Quality metrics for reasoning assessment
/// Following Single Responsibility: Represents quality dimensions
public struct QualityMetrics: Sendable {
    public let hallucinationRisk: Double
    public let contextGrounding: Double
    public let logicalConsistency: Double
    public let assumptionQuality: Double
    public let overallReliability: Double

    public init(
        hallucinationRisk: Double,
        contextGrounding: Double,
        logicalConsistency: Double,
        assumptionQuality: Double,
        overallReliability: Double
    ) {
        self.hallucinationRisk = hallucinationRisk
        self.contextGrounding = contextGrounding
        self.logicalConsistency = logicalConsistency
        self.assumptionQuality = assumptionQuality
        self.overallReliability = overallReliability
    }
}

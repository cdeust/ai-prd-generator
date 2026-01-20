import Foundation

/// Verification of plan execution
public struct PlanVerification: Sendable {
    public let isComplete: Bool
    public let completenessScore: Double
    public let identifiedGaps: [String]
    public let recommendations: [String]

    public init(
        isComplete: Bool,
        completenessScore: Double,
        identifiedGaps: [String],
        recommendations: [String]
    ) {
        self.isComplete = isComplete
        self.completenessScore = completenessScore
        self.identifiedGaps = identifiedGaps
        self.recommendations = recommendations
    }
}

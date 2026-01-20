import Foundation

/// Decision on whether to refine based on trajectory analysis
/// Single Responsibility: Represents refinement decision with reasoning
public struct RefinementDecision: Sendable {
    public let shouldRefine: Bool
    public let reason: String
    public let maxAdditionalAttempts: Int
    public let confidence: Double
    public let trajectory: RefinementTrajectory

    public init(
        shouldRefine: Bool,
        reason: String,
        maxAdditionalAttempts: Int,
        confidence: Double,
        trajectory: RefinementTrajectory
    ) {
        self.shouldRefine = shouldRefine
        self.reason = reason
        self.maxAdditionalAttempts = maxAdditionalAttempts
        self.confidence = confidence
        self.trajectory = trajectory
    }
}

import Foundation

/// Analysis of refinement trajectory (improving vs diminishing returns)
/// Single Responsibility: Represents trajectory analysis metrics
public struct RefinementTrajectory: Sendable {
    public let isImproving: Bool
    public let isDiminishing: Bool
    public let improvement: Double  // Average improvement per attempt

    public init(
        isImproving: Bool,
        isDiminishing: Bool,
        improvement: Double
    ) {
        self.isImproving = isImproving
        self.isDiminishing = isDiminishing
        self.improvement = improvement
    }
}

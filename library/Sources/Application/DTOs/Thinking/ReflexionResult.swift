import Foundation
import Domain

/// Final result of Reflexion process
public struct ReflexionResult: Sendable, RefinableResult {
    public let problem: String
    public let finalConclusion: String
    public let finalQualityScore: Double
    public let reflectionMemory: [ReflectionEntry]
    public let iterationsUsed: Int
    public let improvementTrajectory: [Double]

    public init(
        problem: String,
        finalConclusion: String,
        finalQualityScore: Double,
        reflectionMemory: [ReflectionEntry],
        iterationsUsed: Int,
        improvementTrajectory: [Double]
    ) {
        self.problem = problem
        self.finalConclusion = finalConclusion
        self.finalQualityScore = finalQualityScore
        self.reflectionMemory = reflectionMemory
        self.iterationsUsed = iterationsUsed
        self.improvementTrajectory = improvementTrajectory
    }

    public var didImprove: Bool {
        guard improvementTrajectory.count > 1 else { return false }
        return improvementTrajectory.last! > improvementTrajectory.first!
    }

    public var averageImprovement: Double {
        guard improvementTrajectory.count > 1 else { return 0.0 }
        return improvementTrajectory.last! - improvementTrajectory.first!
    }

    // MARK: - RefinableResult Conformance

    /// Conclusion for refinement (maps to finalConclusion)
    public var conclusion: String {
        finalConclusion
    }

    /// Confidence score for refinement (maps to finalQualityScore)
    public var confidence: Double {
        finalQualityScore
    }
}

import Foundation
import Domain

/// Final result of Plan-and-Solve
public struct PlanAndSolveResult: Sendable, RefinableResult {
    public let problem: String
    public let plan: ExecutionPlan
    public let executionResults: [StepResult]
    public let verification: PlanVerification
    public let finalOutput: String
    public let averageConfidence: Double

    public init(
        problem: String,
        plan: ExecutionPlan,
        executionResults: [StepResult],
        verification: PlanVerification,
        finalOutput: String,
        averageConfidence: Double
    ) {
        self.problem = problem
        self.plan = plan
        self.executionResults = executionResults
        self.verification = verification
        self.finalOutput = finalOutput
        self.averageConfidence = averageConfidence
    }

    // MARK: - RefinableResult Conformance

    /// Conclusion for refinement (maps to finalOutput)
    public var conclusion: String {
        finalOutput
    }

    /// Confidence score for refinement (maps to averageConfidence)
    public var confidence: Double {
        averageConfidence
    }
}

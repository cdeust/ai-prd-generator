import Foundation

/// Result from prompt chaining
public struct PromptChainingResult: Sendable {
    public let solution: String
    public let problem: String
    public let stepsExecuted: [StepOutput]
    public let confidence: Double

    public init(solution: String, problem: String, stepsExecuted: [StepOutput], confidence: Double) {
        self.solution = solution
        self.problem = problem
        self.stepsExecuted = stepsExecuted
        self.confidence = confidence
    }
}

import Foundation

/// Result from few-shot reasoning
public struct FewShotResult: Sendable {
    public let solution: String
    public let problem: String
    public let examplesUsed: Int
    public let confidence: Double

    public init(solution: String, problem: String, examplesUsed: Int, confidence: Double) {
        self.solution = solution
        self.problem = problem
        self.examplesUsed = examplesUsed
        self.confidence = confidence
    }
}

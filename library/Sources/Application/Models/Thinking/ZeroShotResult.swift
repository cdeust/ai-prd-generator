import Foundation

/// Result from zero-shot reasoning
public struct ZeroShotResult: Sendable {
    public let solution: String
    public let problem: String
    public let confidence: Double

    public init(solution: String, problem: String, confidence: Double) {
        self.solution = solution
        self.problem = problem
        self.confidence = confidence
    }
}

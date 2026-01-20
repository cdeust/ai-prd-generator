import Foundation

/// Final orchestrated thinking result
public struct ThinkingResult: Sendable {
    public let problem: String
    public let strategyUsed: ThinkingStrategy
    public let conclusion: String
    public let confidence: Double
    public let metadata: [String: String]
    public let timestamp: Date

    public init(
        problem: String,
        strategyUsed: ThinkingStrategy,
        conclusion: String,
        confidence: Double,
        metadata: [String: String],
        timestamp: Date
    ) {
        self.problem = problem
        self.strategyUsed = strategyUsed
        self.conclusion = conclusion
        self.confidence = confidence
        self.metadata = metadata
        self.timestamp = timestamp
    }
}

import Foundation

/// Internal result from strategy execution
public struct StrategyResult: Sendable {
    public let conclusion: String
    public let confidence: Double
    public let metadata: [String: String]

    public init(
        conclusion: String,
        confidence: Double,
        metadata: [String: String]
    ) {
        self.conclusion = conclusion
        self.confidence = confidence
        self.metadata = metadata
    }
}

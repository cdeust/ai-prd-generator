import Foundation

/// Plan generated from reasoning analysis
public struct ReasoningPlan: Sendable {
    public let steps: [String]
    public let keyDecisions: [String]
    public let confidence: Double

    public init(
        steps: [String],
        keyDecisions: [String],
        confidence: Double
    ) {
        self.steps = steps
        self.keyDecisions = keyDecisions
        self.confidence = confidence
    }
}

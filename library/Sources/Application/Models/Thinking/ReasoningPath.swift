import Foundation

/// Individual reasoning path from self-consistency
public struct ReasoningPath: Sendable {
    public let reasoning: String
    public let answer: String
    public let confidence: Double

    public init(reasoning: String, answer: String, confidence: Double) {
        self.reasoning = reasoning
        self.answer = answer
        self.confidence = confidence
    }
}

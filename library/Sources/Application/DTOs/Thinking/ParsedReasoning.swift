import Foundation
import Domain

/// Parsed reasoning result from structured CoT
/// Following Single Responsibility: Represents parsed reasoning output
public struct ParsedReasoning: Sendable {
    public let thoughts: [Thought]
    public let assumptions: [Assumption]
    public let inferences: [String]
    public let conclusion: String
    public let confidence: Double
    public let rawResponse: String

    public init(
        thoughts: [Thought],
        assumptions: [Assumption],
        inferences: [String],
        conclusion: String,
        confidence: Double,
        rawResponse: String
    ) {
        self.thoughts = thoughts
        self.assumptions = assumptions
        self.inferences = inferences
        self.conclusion = conclusion
        self.confidence = confidence
        self.rawResponse = rawResponse
    }
}

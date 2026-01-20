import Foundation

/// Single hop in multi-hop reasoning
/// Following Single Responsibility: Represents one reasoning step
public struct ReasoningHop: Identifiable, Sendable {
    public let id: UUID
    public let hopNumber: Int
    public let question: String
    public let thoughts: [Thought]
    public let assumptions: [Assumption]
    public let inferences: [String]
    public let conclusion: String
    public let confidence: Double
    public let sourceContext: String
    public let rawResponse: String
    public let wasCorrected: Bool

    public init(
        id: UUID,
        hopNumber: Int,
        question: String,
        thoughts: [Thought],
        assumptions: [Assumption],
        inferences: [String],
        conclusion: String,
        confidence: Double,
        sourceContext: String,
        rawResponse: String,
        wasCorrected: Bool = false
    ) {
        self.id = id
        self.hopNumber = hopNumber
        self.question = question
        self.thoughts = thoughts
        self.assumptions = assumptions
        self.inferences = inferences
        self.conclusion = conclusion
        self.confidence = confidence
        self.sourceContext = sourceContext
        self.rawResponse = rawResponse
        self.wasCorrected = wasCorrected
    }
}

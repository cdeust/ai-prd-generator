import Foundation

/// Chain of thought for structured reasoning
/// Following Single Responsibility: Manages thought chain entity only
public struct ThoughtChain: Identifiable, Sendable, Codable, RefinableResult {
    public let id: UUID
    public let problem: String
    public let thoughts: [Thought]
    public let conclusion: String
    public let confidence: Double
    public let alternatives: [Alternative]
    public let assumptions: [Assumption]
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        problem: String,
        thoughts: [Thought],
        conclusion: String,
        confidence: Double,
        alternatives: [Alternative] = [],
        assumptions: [Assumption] = [],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.problem = problem
        self.thoughts = thoughts
        self.conclusion = conclusion
        self.confidence = confidence
        self.alternatives = alternatives
        self.assumptions = assumptions
        self.timestamp = timestamp
    }
}

import Foundation

/// Verified thought chain with multi-hop reasoning
/// Following Single Responsibility: Represents verified reasoning chain
public struct VerifiedThoughtChain: Sendable, RefinableResult {
    public let id: UUID
    public let problem: String
    public let hops: [ReasoningHop]
    public let thoughts: [Thought]
    public let conclusion: String
    public let confidence: Double
    public let assumptions: [Assumption]
    public let timestamp: Date
    public let wasVerified: Bool

    public init(
        id: UUID,
        problem: String,
        hops: [ReasoningHop],
        thoughts: [Thought],
        conclusion: String,
        confidence: Double,
        assumptions: [Assumption],
        timestamp: Date,
        wasVerified: Bool
    ) {
        self.id = id
        self.problem = problem
        self.hops = hops
        self.thoughts = thoughts
        self.conclusion = conclusion
        self.confidence = confidence
        self.assumptions = assumptions
        self.timestamp = timestamp
        self.wasVerified = wasVerified
    }
}

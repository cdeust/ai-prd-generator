import Foundation

/// Node in decision tree
/// Following Single Responsibility: Represents tree node only
public struct DecisionNode: Identifiable, Sendable {
    public let id: UUID
    public let question: String
    public let criteria: [String]
    public let children: [DecisionNode]
    public let outcome: String?

    // Properties for Tree-of-Thoughts
    public let reasoning: String
    public let score: Double
    public let depth: Int
    public let path: [String]

    public init(
        id: UUID = UUID(),
        question: String,
        criteria: [String] = [],
        children: [DecisionNode] = [],
        outcome: String? = nil,
        reasoning: String = "",
        score: Double = 0.0,
        depth: Int = 0,
        path: [String] = []
    ) {
        self.id = id
        self.question = question
        self.criteria = criteria
        self.children = children
        self.outcome = outcome
        self.reasoning = reasoning
        self.score = score
        self.depth = depth
        self.path = path
    }
}

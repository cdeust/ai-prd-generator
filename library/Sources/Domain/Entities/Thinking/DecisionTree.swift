import Foundation

/// Decision tree for structured decision making
/// Following Single Responsibility: Manages decision tree structure only
public struct DecisionTree: Identifiable, Sendable {
    public let id: UUID
    public let rootQuestion: String
    public let rootNode: DecisionNode
    public let createdAt: Date

    // Properties for Tree-of-Thoughts analysis
    public let bestPath: [String]
    public let bestScore: Double
    public let totalNodesExplored: Int

    public init(
        id: UUID = UUID(),
        rootQuestion: String = "",
        rootNode: DecisionNode,
        createdAt: Date = Date(),
        bestPath: [String] = [],
        bestScore: Double = 0.0,
        totalNodesExplored: Int = 0
    ) {
        self.id = id
        self.rootQuestion = rootQuestion
        self.rootNode = rootNode
        self.createdAt = createdAt
        self.bestPath = bestPath
        self.bestScore = bestScore
        self.totalNodesExplored = totalNodesExplored
    }
}

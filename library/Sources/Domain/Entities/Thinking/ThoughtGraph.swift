import Foundation

/// Graph structure for advanced reasoning
/// Following Single Responsibility: Represents interconnected thought structure
public struct ThoughtGraph: Identifiable, Sendable {
    public let id: UUID
    public let problem: String
    public var nodes: [ContextNode]
    public var edges: [ContextEdge]
    public var synthesis: String?  // Final synthesized conclusion
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        problem: String,
        nodes: [ContextNode] = [],
        edges: [ContextEdge] = [],
        synthesis: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.problem = problem
        self.nodes = nodes
        self.edges = edges
        self.synthesis = synthesis
        self.timestamp = timestamp
    }

    /// Add a new node to the graph
    public mutating func addNode(_ node: ContextNode) {
        nodes.append(node)
    }

    /// Add a new edge to the graph
    public mutating func addEdge(_ edge: ContextEdge) {
        edges.append(edge)
    }

    /// Set the synthesis conclusion
    public mutating func setSynthesis(_ conclusion: String) {
        synthesis = conclusion
    }
}

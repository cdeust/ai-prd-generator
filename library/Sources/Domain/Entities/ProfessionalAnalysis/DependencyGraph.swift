import Foundation

/// Dependency graph for component relationships
/// Following Single Responsibility Principle - represents dependency graph
public struct DependencyGraph: Sendable, Codable {
    public let nodes: [DependencyNode]
    public let edges: [DependencyEdge]

    public init(nodes: [DependencyNode], edges: [DependencyEdge]) {
        self.nodes = nodes
        self.edges = edges
    }
}

import Foundation
import Domain

/// Graph-based context tracking for coherent reasoning
/// Maintains relationships between retrieved chunks and reasoning steps
/// Following Single Responsibility: Tracks context relationships only
public actor ContextGraphTracker {
    private var nodes: [UUID: ContextNode] = [:]
    private var edges: [ContextEdge] = []
    private var activePath: [UUID] = []

    public init() {}

    /// Add context node (chunk, thought, or reference)
    public func addNode(_ node: ContextNode) {
        nodes[node.id] = node
        activePath.append(node.id)
    }

    /// Link two nodes with relationship
    public func link(
        from sourceId: UUID,
        to targetId: UUID,
        relationship: ContextRelationship,
        strength: Double = 1.0
    ) {
        let edge = ContextEdge(
            id: UUID(),
            source: sourceId,
            target: targetId,
            relationship: relationship,
            strength: strength,
            timestamp: Date()
        )
        edges.append(edge)
    }

    /// Get relevant context for current reasoning step
    public func getRelevantContext(
        for query: String,
        maxNodes: Int = 10
    ) -> [ContextNode] {
        // Start from most recent nodes in active path
        var relevant: [(node: ContextNode, score: Double)] = []

        for (index, nodeId) in activePath.reversed().enumerated() {
            guard let node = nodes[nodeId] else { continue }

            // Recency score (recent = higher score)
            let recencyScore = 1.0 / Double(index + 1)

            // Relationship score (connected to active path = higher)
            let relationshipScore = calculateRelationshipScore(for: node)

            // Content relevance (simple keyword matching, can use embeddings)
            let relevanceScore = calculateRelevanceScore(node: node, query: query)

            let totalScore = (recencyScore * 0.3) + (relationshipScore * 0.4) + (relevanceScore * 0.3)

            relevant.append((node, totalScore))
        }

        return relevant
            .sorted { $0.score > $1.score }
            .prefix(maxNodes)
            .map(\.node)
    }

    /// Get context path from root to current node
    public func getContextPath() -> [ContextNode] {
        activePath.compactMap { nodes[$0] }
    }

    /// Check for circular dependencies
    public func hasCircularDependency(from nodeId: UUID, to targetId: UUID) -> Bool {
        let visited: Set<UUID> = []
        return detectCycle(current: targetId, target: nodeId, visited: visited)
    }

    /// Prune irrelevant context (memory management)
    public func pruneIrrelevantContext(keepRecent: Int = 20) {
        guard activePath.count > keepRecent * 2 else { return }

        let toRemove = Set(activePath.prefix(activePath.count - keepRecent))

        // Remove nodes
        for nodeId in toRemove {
            nodes.removeValue(forKey: nodeId)
        }

        // Remove edges
        edges.removeAll { edge in
            toRemove.contains(edge.source) || toRemove.contains(edge.target)
        }

        // Update active path
        activePath = Array(activePath.suffix(keepRecent))
    }

    // MARK: - Private Helpers

    private func calculateRelationshipScore(for node: ContextNode) -> Double {
        let incomingEdges = edges.filter { $0.target == node.id }
        let outgoingEdges = edges.filter { $0.source == node.id }

        let totalConnections = Double(incomingEdges.count + outgoingEdges.count)
        let strongConnections = incomingEdges.filter { $0.strength > 0.7 }.count +
                                outgoingEdges.filter { $0.strength > 0.7 }.count

        return totalConnections > 0 ? Double(strongConnections) / totalConnections : 0.0
    }

    private func calculateRelevanceScore(node: ContextNode, query: String) -> Double {
        let queryTerms = Set(query.lowercased().split(separator: " ").map(String.init))
        let nodeTerms = Set(node.content.lowercased().split(separator: " ").map(String.init))

        let intersection = queryTerms.intersection(nodeTerms)
        let union = queryTerms.union(nodeTerms)

        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }

    private func detectCycle(
        current: UUID,
        target: UUID,
        visited: Set<UUID>
    ) -> Bool {
        if current == target { return true }
        if visited.contains(current) { return false }

        var newVisited = visited
        newVisited.insert(current)

        let nextNodes = edges
            .filter { $0.source == current }
            .map(\.target)

        for next in nextNodes {
            if detectCycle(current: next, target: target, visited: newVisited) {
                return true
            }
        }

        return false
    }
}


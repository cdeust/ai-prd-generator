import Foundation
import Domain

/// Builds and analyzes decision trees
/// Single Responsibility: Reconstruct tree structure and find optimal paths
public struct TreeBuilder: Sendable {
    public init() {}

    /// Build tree from explored nodes
    public func build(
        from nodes: [DecisionNode],
        root: DecisionNode
    ) -> DecisionTree {
        let bestLeaf = findBestLeaf(in: nodes)
        let reconstructedRoot = reconstructNode(root, from: nodes)

        return DecisionTree(
            id: UUID(),
            rootQuestion: root.question,
            rootNode: reconstructedRoot,
            createdAt: Date(),
            bestPath: bestLeaf?.path ?? [],
            bestScore: bestLeaf?.score ?? 0.0,
            totalNodesExplored: nodes.count
        )
    }

    /// Add children to node
    public func addChildren(
        to node: DecisionNode,
        children: [DecisionNode]
    ) -> DecisionNode {
        DecisionNode(
            id: node.id,
            question: node.question,
            criteria: node.criteria,
            children: children,
            outcome: node.outcome,
            reasoning: node.reasoning,
            score: node.score,
            depth: node.depth,
            path: node.path
        )
    }

    // MARK: - Private Methods

    private func findBestLeaf(in nodes: [DecisionNode]) -> DecisionNode? {
        nodes
            .filter { $0.children.isEmpty }
            .max { $0.score < $1.score }
    }

    private func reconstructNode(
        _ node: DecisionNode,
        from allNodes: [DecisionNode]
    ) -> DecisionNode {
        let children = findChildren(of: node, in: allNodes)

        if children.isEmpty {
            return node
        }

        let reconstructedChildren = children.map { child in
            reconstructNode(child, from: allNodes)
        }

        return DecisionNode(
            id: node.id,
            question: node.question,
            criteria: node.criteria,
            children: reconstructedChildren,
            outcome: node.outcome,
            reasoning: node.reasoning,
            score: node.score,
            depth: node.depth,
            path: node.path
        )
    }

    private func findChildren(
        of node: DecisionNode,
        in allNodes: [DecisionNode]
    ) -> [DecisionNode] {
        allNodes.filter { child in
            child.depth == node.depth + 1 &&
            child.path.dropLast() == node.path
        }
    }
}

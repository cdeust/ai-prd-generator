import Foundation
import Domain

/// Tree-of-Thoughts reasoning: Explores multiple reasoning paths in a tree structure
/// Single Responsibility: Orchestrates branching exploration with pruning
public struct TreeOfThoughtsUseCase: Sendable {
    private let branchGenerator: TreeBranchGenerator
    private let nodeEvaluator: TreeNodeEvaluator
    private let treeBuilder: TreeBuilder

    public init(aiProvider: AIProviderPort) {
        self.branchGenerator = TreeBranchGenerator(aiProvider: aiProvider)
        self.nodeEvaluator = TreeNodeEvaluator(aiProvider: aiProvider)
        self.treeBuilder = TreeBuilder()
    }

    /// Execute Tree-of-Thoughts with breadth-first search and pruning
    public func execute(
        problem: String,
        context: String = "",
        branchingFactor: Int = 3,
        maxDepth: Int = 3,
        pruningThreshold: Double = 0.6
    ) async throws -> DecisionTree {
        let rootNode = createRootNode(problem: problem)

        return try await exploreTree(
            root: rootNode,
            context: context,
            branchingFactor: branchingFactor,
            maxDepth: maxDepth,
            pruningThreshold: pruningThreshold
        )
    }

    // MARK: - Private Methods

    private func createRootNode(problem: String) -> DecisionNode {
        DecisionNode(
            id: UUID(),
            question: problem,
            criteria: [],
            children: [],
            outcome: nil,
            reasoning: "",
            score: 1.0,
            depth: 0,
            path: []
        )
    }

    private func exploreTree(
        root: DecisionNode,
        context: String,
        branchingFactor: Int,
        maxDepth: Int,
        pruningThreshold: Double
    ) async throws -> DecisionTree {
        var frontier: [DecisionNode] = [root]
        var exploredNodes: [DecisionNode] = []

        while !frontier.isEmpty && frontier.first!.depth < maxDepth {
            let currentNode = frontier.removeFirst()

            let children = try await branchGenerator.generate(
                node: currentNode,
                context: context,
                branchingFactor: branchingFactor
            )

            let evaluatedChildren = try await nodeEvaluator.evaluateBatch(
                children,
                context: context
            )

            let prunedChildren = nodeEvaluator.prune(
                evaluatedChildren,
                threshold: pruningThreshold
            )

            let updatedNode = treeBuilder.addChildren(
                to: currentNode,
                children: prunedChildren
            )

            exploredNodes.append(updatedNode)

            let sortedChildren = prunedChildren.sorted { $0.score > $1.score }
            frontier.append(contentsOf: sortedChildren)
        }

        return treeBuilder.build(from: exploredNodes, root: root)
    }
}

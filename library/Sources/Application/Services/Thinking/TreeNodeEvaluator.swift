import Foundation
import Domain

/// Evaluates tree nodes for promise and quality
/// Single Responsibility: Score nodes to guide exploration
public struct TreeNodeEvaluator: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    /// Evaluate multiple nodes in parallel
    public func evaluateBatch(
        _ nodes: [DecisionNode],
        context: String
    ) async throws -> [DecisionNode] {
        try await withThrowingTaskGroup(of: DecisionNode.self) { group in
            for node in nodes {
                group.addTask {
                    try await self.evaluate(node, context: context)
                }
            }

            var evaluatedNodes: [DecisionNode] = []
            for try await node in group {
                evaluatedNodes.append(node)
            }
            return evaluatedNodes
        }
    }

    /// Evaluate single node
    public func evaluate(
        _ node: DecisionNode,
        context: String
    ) async throws -> DecisionNode {
        let score = try await scoreNode(node: node, context: context)
        return updateScore(node, score: score)
    }

    /// Prune weak branches based on threshold
    public func prune(
        _ nodes: [DecisionNode],
        threshold: Double
    ) -> [DecisionNode] {
        nodes.filter { $0.score >= threshold }
    }

    // MARK: - Private Methods

    private func scoreNode(
        node: DecisionNode,
        context: String
    ) async throws -> Double {
        let prompt = buildScoringPrompt(node: node, context: context)

        let response = try await aiProvider.generateText(
            prompt: prompt,
            temperature: 0.0
        )

        return parseScore(from: response)
    }

    private func buildScoringPrompt(
        node: DecisionNode,
        context: String
    ) -> String {
        """
        Evaluate the promise of this reasoning step on a scale of 0.0 to 1.0:

        <step>
        \(node.question)
        </step>

        <reasoning>
        \(node.reasoning)
        </reasoning>

        <context>
        \(context)
        </context>

        Consider:
        - Logical soundness
        - Alignment with context
        - Likelihood of reaching correct solution

        Respond with only a decimal number between 0.0 and 1.0.
        """
    }

    private func parseScore(from response: String) -> Double {
        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned) ?? 0.5
    }

    private func updateScore(
        _ node: DecisionNode,
        score: Double
    ) -> DecisionNode {
        DecisionNode(
            id: node.id,
            question: node.question,
            criteria: node.criteria,
            children: node.children,
            outcome: node.outcome,
            reasoning: node.reasoning,
            score: score,
            depth: node.depth,
            path: node.path
        )
    }
}

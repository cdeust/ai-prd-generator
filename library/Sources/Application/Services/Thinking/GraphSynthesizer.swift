import Foundation
import Domain

/// Synthesizes thought graphs into coherent conclusions
/// Single Responsibility: Transform graph structure into actionable insights
public struct GraphSynthesizer: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    /// Synthesize graph into final conclusion
    public func synthesize(
        graph: ThoughtGraph,
        context: String
    ) async throws -> String {
        let prompt = buildSynthesisPrompt(graph: graph, context: context)

        let response = try await aiProvider.generateText(
            prompt: prompt,
            temperature: 0.2
        )

        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Check if graph has converged
    public func hasConverged(
        graph: ThoughtGraph,
        threshold: Double
    ) -> Bool {
        let recentNodes = graph.nodes.suffix(3)
        guard !recentNodes.isEmpty else { return false }

        let totalConfidence = recentNodes.map(\.confidence).reduce(0.0, +)
        let avgConfidence = totalConfidence / Double(recentNodes.count)

        let recentEdges = graph.edges.suffix(5)
        let hasStrongConnections = !recentEdges.isEmpty &&
            recentEdges.map(\.strength).reduce(0.0, +) / Double(recentEdges.count) > 0.7

        return avgConfidence > threshold && hasStrongConnections
    }

    // MARK: - Private Methods

    private func buildSynthesisPrompt(
        graph: ThoughtGraph,
        context: String
    ) -> String {
        let nodeSummaries = graph.nodes
            .filter { $0.type != .question }
            .map { "- [\($0.type)]: \($0.content)" }
            .joined(separator: "\n")

        let edgeSummaries = graph.edges
            .map { "- \($0.relationship) (strength: \(String(format: "%.2f", $0.strength)))" }
            .joined(separator: "\n")

        return """
        Synthesize the following reasoning graph into a coherent conclusion:

        <problem>
        \(graph.problem)
        </problem>

        <thought_nodes>
        \(nodeSummaries)
        </thought_nodes>

        <connections>
        \(edgeSummaries)
        </connections>

        <context>
        \(context)
        </context>

        Provide a synthesis that:
        1. Integrates the strongest insights
        2. Resolves contradictions if any
        3. Acknowledges key assumptions
        4. Provides actionable conclusion
        5. Notes confidence level and limitations
        """
    }
}

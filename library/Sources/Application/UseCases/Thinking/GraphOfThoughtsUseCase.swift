import Foundation
import Domain

/// Graph-of-Thoughts reasoning: Non-linear reasoning with interconnected thought nodes
/// Single Responsibility: Orchestrates graph-based exploration with synthesis
public struct GraphOfThoughtsUseCase: Sendable {
    private let nodeGenerator: GraphNodeGenerator
    private let connectionAnalyzer: GraphConnectionAnalyzer
    private let synthesizer: GraphSynthesizer

    public init(aiProvider: AIProviderPort) {
        self.nodeGenerator = GraphNodeGenerator(aiProvider: aiProvider)
        self.connectionAnalyzer = GraphConnectionAnalyzer(aiProvider: aiProvider)
        self.synthesizer = GraphSynthesizer(aiProvider: aiProvider)
    }

    /// Execute Graph-of-Thoughts with aggregation and synthesis
    public func execute(
        problem: String,
        context: String = "",
        maxNodes: Int = 10,
        convergenceThreshold: Double = 0.85
    ) async throws -> ThoughtGraph {
        var graph = initializeGraph(problem: problem)

        for iteration in 0..<maxNodes {
            let newNode = try await nodeGenerator.generate(
                currentGraph: graph,
                context: context,
                iteration: iteration
            )

            graph = addNode(to: graph, newNode: newNode)

            let connections = try await connectionAnalyzer.identifyConnections(
                newNode: newNode,
                existingNodes: graph.nodes,
                context: context
            )

            graph = addConnections(to: graph, connections: connections)

            if synthesizer.hasConverged(
                graph: graph,
                threshold: convergenceThreshold
            ) {
                break
            }
        }

        let synthesis = try await synthesizer.synthesize(
            graph: graph,
            context: context
        )

        return withSynthesis(graph: graph, synthesis: synthesis)
    }

    // MARK: - Private Methods

    private func initializeGraph(problem: String) -> ThoughtGraph {
        let rootNode = ContextNode(
            id: UUID(),
            type: .question,
            content: problem,
            confidence: 1.0,
            metadata: ["role": "root"]
        )

        return ThoughtGraph(
            id: UUID(),
            problem: problem,
            nodes: [rootNode],
            edges: [],
            synthesis: nil,
            timestamp: Date()
        )
    }

    private func addNode(
        to graph: ThoughtGraph,
        newNode: ContextNode
    ) -> ThoughtGraph {
        ThoughtGraph(
            id: graph.id,
            problem: graph.problem,
            nodes: graph.nodes + [newNode],
            edges: graph.edges,
            synthesis: graph.synthesis,
            timestamp: graph.timestamp
        )
    }

    private func addConnections(
        to graph: ThoughtGraph,
        connections: [ContextEdge]
    ) -> ThoughtGraph {
        ThoughtGraph(
            id: graph.id,
            problem: graph.problem,
            nodes: graph.nodes,
            edges: graph.edges + connections,
            synthesis: graph.synthesis,
            timestamp: graph.timestamp
        )
    }

    private func withSynthesis(
        graph: ThoughtGraph,
        synthesis: String
    ) -> ThoughtGraph {
        ThoughtGraph(
            id: graph.id,
            problem: graph.problem,
            nodes: graph.nodes,
            edges: graph.edges,
            synthesis: synthesis,
            timestamp: Date()
        )
    }
}

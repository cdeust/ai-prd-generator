import Foundation
import Domain

/// Context-aware filtering for search results
/// Following Single Responsibility: Applies context-based relevance boosting
public struct ContextAwareFilter: Sendable {
    private let contextTracker: ContextGraphTracker

    public init(contextTracker: ContextGraphTracker) {
        self.contextTracker = contextTracker
    }

    /// Filter and boost results based on context relevance
    public func filterByContextRelevance(
        results: [HybridSearchResult],
        currentContext: String
    ) async -> [HybridSearchResult] {
        let relevantNodes = await contextTracker.getRelevantContext(
            for: currentContext,
            maxNodes: 20
        )

        let relevantFilePaths = extractRelevantFilePaths(from: relevantNodes)
        let boostedResults = boostAndPenalize(
            results: results,
            relevantFilePaths: relevantFilePaths,
            relevantNodes: relevantNodes
        )

        return boostedResults.sorted { $0.hybridScore > $1.hybridScore }
    }

    private func extractRelevantFilePaths(from nodes: [ContextNode]) -> Set<String> {
        Set(nodes.compactMap { node -> String? in
            if case .codeChunk(let path) = node.type {
                return path
            }
            return nil
        })
    }

    private func boostAndPenalize(
        results: [HybridSearchResult],
        relevantFilePaths: Set<String>,
        relevantNodes: [ContextNode]
    ) -> [HybridSearchResult] {
        results.map { result in
            var boostedScore = result.hybridScore

            if relevantFilePaths.contains(result.chunk.filePath) {
                boostedScore *= 1.3 // 30% boost for context-related files
            }

            let isDuplicate = relevantNodes.contains { node in
                node.content.contains(result.chunk.content)
            }

            if isDuplicate {
                boostedScore *= 0.5 // Penalize duplicates
            }

            return HybridSearchResult(
                chunk: result.chunk,
                vectorSimilarity: result.vectorSimilarity,
                bm25Score: result.bm25Score,
                hybridScore: boostedScore
            )
        }
    }
}

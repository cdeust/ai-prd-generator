import AIPRDSharedUtilities
import AIPRDRAGEngine
import Foundation
import AIPRDSharedUtilities

/// Use case for searching codebase using hybrid search
/// Following SRP - handles codebase search orchestration
/// Following DIP - depends on RAGEngineProtocol
public struct SearchCodebaseUseCase: Sendable {
    private let ragEngine: RAGEngineProtocol

    public init(ragEngine: RAGEngineProtocol) {
        self.ragEngine = ragEngine
    }

    public func execute(
        codebaseId: UUID,
        query: String,
        limit: Int = 10
    ) async throws -> [CodebaseSearchResult] {
        let results = try await ragEngine.hybridSearch(
            query: query,
            projectId: codebaseId,
            limit: limit,
            alpha: 0.7,
            similarityThreshold: 0.5
        )

        return results.map { hybrid in
            CodebaseSearchResult(
                chunk: hybrid.chunk,
                score: hybrid.hybridScore,
                vectorScore: hybrid.vectorSimilarity ?? 0.0,
                keywordScore: hybrid.bm25Score ?? 0.0
            )
        }
    }
}

import Foundation
import Domain

/// Use case for searching codebase using hybrid search
/// Following SRP - handles codebase search orchestration
/// Following DIP - depends on HybridSearchService
public struct SearchCodebaseUseCase: Sendable {
    private let hybridSearch: HybridSearchService

    public init(hybridSearch: HybridSearchService) {
        self.hybridSearch = hybridSearch
    }

    public func execute(
        codebaseId: UUID,
        query: String,
        limit: Int = 10
    ) async throws -> [CodebaseSearchResult] {
        let results = try await hybridSearch.search(
            query: query,
            projectId: codebaseId,
            limit: limit
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

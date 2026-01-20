import Foundation
import Domain

/// RAG retrieval orchestrator specifically for Chain-of-Thought reasoning
///
/// **3R's Justification:**
/// - **Reliability**: Testable RAG logic in isolation
/// - **Readability**: Clear separation of RAG from reasoning logic
/// - **Reusability**: Any CoT variant can use this RAG wrapper
///
/// Single Responsibility: Retrieve and format codebase context for CoT reasoning
public struct CoTRAGRetriever: Sendable {
    private let aiProvider: AIProviderPort
    private let codebaseRepository: CodebaseRepositoryPort?
    private let embeddingGenerator: EmbeddingGeneratorPort?
    private let fullTextSearch: FullTextSearchPort?
    private let queryExpander: QueryExpansionService?
    private let hybridSearch: HybridSearchService?
    private let reranker: RerankingService?
    private let contextFormatter: CodeContextFormatter

    public init(
        aiProvider: AIProviderPort,
        codebaseRepository: CodebaseRepositoryPort?,
        embeddingGenerator: EmbeddingGeneratorPort?,
        fullTextSearch: FullTextSearchPort?
    ) {
        self.aiProvider = aiProvider
        self.codebaseRepository = codebaseRepository
        self.embeddingGenerator = embeddingGenerator
        self.fullTextSearch = fullTextSearch
        self.queryExpander = QueryExpansionService(aiProvider: aiProvider)
        self.contextFormatter = CodeContextFormatter()

        if let repo = codebaseRepository,
           let embedder = embeddingGenerator,
           let fts = fullTextSearch {
            self.hybridSearch = HybridSearchService(
                codebaseRepository: repo,
                embeddingGenerator: embedder,
                fullTextSearch: fts
            )
            self.reranker = RerankingService(aiProvider: aiProvider)
        } else {
            self.hybridSearch = nil
            self.reranker = nil
        }
    }

    /// Retrieve RAG context for a query
    public func retrieveContext(
        query: String,
        codebaseId: UUID,
        baseContext: String
    ) async throws -> String {
        let expandedQuery = try await expandQuery(query: query, context: baseContext)
        let searchResults = try await performSearch(
            query: query,
            expandedQuery: expandedQuery,
            codebaseId: codebaseId
        )
        let rerankedChunks = try await rerankResults(
            searchResults: searchResults,
            query: query
        )

        return contextFormatter.format(chunks: rerankedChunks)
    }

    // MARK: - Private Methods

    private func expandQuery(
        query: String,
        context: String
    ) async throws -> ExpandedQuery? {
        guard let expander = queryExpander else { return nil }
        return try await expander.expandWithHyDE(query: query, context: context)
    }

    private func performSearch(
        query: String,
        expandedQuery: ExpandedQuery?,
        codebaseId: UUID
    ) async throws -> [HybridSearchResult] {
        if let hybrid = hybridSearch {
            let searchQuery = expandedQuery?.hypotheticalDocument ?? query
            return try await hybrid.search(
                query: searchQuery,
                projectId: codebaseId,
                limit: 10,
                alpha: 0.7
            )
        } else {
            return try await performBasicVectorSearch(
                query: query,
                codebaseId: codebaseId
            )
        }
    }

    private func performBasicVectorSearch(
        query: String,
        codebaseId: UUID
    ) async throws -> [HybridSearchResult] {
        guard let embedder = embeddingGenerator,
              let repo = codebaseRepository else {
            return []
        }

        let embedding = try await embedder.generateEmbedding(text: query)
        let results = try await repo.findSimilarChunks(
            projectId: codebaseId,
            queryEmbedding: embedding,
            limit: 10,
            similarityThreshold: 0.6
        )

        return results.map { HybridSearchResult(
            chunk: $0.chunk,
            vectorSimilarity: Double($0.similarity),
            bm25Score: nil,
            hybridScore: Double($0.similarity)
        )}
    }

    private func rerankResults(
        searchResults: [HybridSearchResult],
        query: String
    ) async throws -> [RankedChunk] {
        if let reranker = reranker {
            let similarChunks = searchResults.map { result -> SimilarCodeChunk in
                SimilarCodeChunk(
                    chunk: result.chunk,
                    similarity: result.vectorSimilarity ?? result.hybridScore
                )
            }
            return try await reranker.rerank(
                chunks: similarChunks,
                query: query,
                topK: 5
            )
        } else {
            return searchResults.prefix(5).map { result -> RankedChunk in
                RankedChunk(
                    chunk: result.chunk,
                    originalSimilarity: result.vectorSimilarity ?? 0,
                    rerankScore: result.hybridScore,
                    finalScore: result.hybridScore
                )
            }
        }
    }
}

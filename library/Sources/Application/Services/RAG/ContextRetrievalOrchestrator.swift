import Foundation
import Domain

/// Context retrieval orchestrator with multi-stage filtering and relationship tracking
/// Following Single Responsibility: Orchestrates contextual retrieval pipeline
public actor ContextRetrievalOrchestrator {
    private let hybridSearch: HybridSearchService
    private let queryExpander: QueryExpansionService
    private let reranker: RerankingService
    private let contextFilter: ContextAwareFilter
    private let graphEnricher: GraphEnricher
    private let aiProvider: AIProviderPort

    public init(
        hybridSearch: HybridSearchService,
        queryExpander: QueryExpansionService,
        reranker: RerankingService,
        aiProvider: AIProviderPort
    ) {
        self.hybridSearch = hybridSearch
        self.queryExpander = queryExpander
        self.reranker = reranker
        self.aiProvider = aiProvider

        let contextTracker = ContextGraphTracker()
        self.contextFilter = ContextAwareFilter(contextTracker: contextTracker)
        self.graphEnricher = GraphEnricher(contextTracker: contextTracker)
    }

    /// Retrieve context with full pipeline and tracking
    public func retrieve(
        query: String,
        projectId: UUID,
        currentContext: String,
        maxChunks: Int = 5
    ) async throws -> ContextualRetrievalResult {
        let pipelineResults = try await executePipeline(
            query: query,
            projectId: projectId,
            currentContext: currentContext,
            maxChunks: maxChunks
        )

        return buildResult(
            expandedQuery: pipelineResults.expandedQuery,
            allResults: pipelineResults.allResults,
            deduplicated: pipelineResults.deduplicated,
            contextFiltered: pipelineResults.contextFiltered,
            reranked: pipelineResults.reranked,
            finalChunks: pipelineResults.finalChunks,
            formattedContext: pipelineResults.formattedContext
        )
    }

    private func executePipeline(
        query: String,
        projectId: UUID,
        currentContext: String,
        maxChunks: Int
    ) async throws -> (
        expandedQuery: ExpandedQuery,
        allResults: [HybridSearchResult],
        deduplicated: [HybridSearchResult],
        contextFiltered: [HybridSearchResult],
        reranked: [RankedChunk],
        finalChunks: [RankedChunk],
        formattedContext: String
    ) {
        let expandedQuery = try await queryExpander.expandWithHyDE(
            query: query,
            context: currentContext
        )
        let allResults = try await performMultiQuerySearch(
            expandedQuery: expandedQuery,
            projectId: projectId
        )
        let deduplicated = deduplicateResults(allResults)
        let contextFiltered = await contextFilter.filterByContextRelevance(
            results: deduplicated,
            currentContext: currentContext
        )
        let reranked = try await rerankWithLLM(
            results: contextFiltered,
            query: query,
            maxChunks: maxChunks
        )
        let graphEnriched = await graphEnricher.enrichWithGraph(
            chunks: reranked,
            query: query,
            currentContext: currentContext
        )
        let finalChunks = selectDiverseChunks(
            chunks: graphEnriched,
            maxCount: maxChunks
        )
        let formattedContext = formatContextWithMetadata(chunks: finalChunks)

        return (expandedQuery, allResults, deduplicated, contextFiltered, reranked, finalChunks, formattedContext)
    }

    // MARK: - Private Pipeline Stages

    private func performMultiQuerySearch(
        expandedQuery: ExpandedQuery,
        projectId: UUID
    ) async throws -> [HybridSearchResult] {
        var allResults: [HybridSearchResult] = []

        for searchQuery in expandedQuery.allQueries.prefix(3) {
            let results = try await hybridSearch.search(
                query: searchQuery,
                projectId: projectId,
                limit: 15,
                alpha: 0.7
            )
            allResults.append(contentsOf: results)
        }

        return allResults
    }

    private func rerankWithLLM(
        results: [HybridSearchResult],
        query: String,
        maxChunks: Int
    ) async throws -> [RankedChunk] {
        let similarChunks = results.map { result in
            SimilarCodeChunk(
                chunk: result.chunk,
                similarity: result.hybridScore
            )
        }

        return try await reranker.rerank(
            chunks: similarChunks,
            query: query,
            topK: maxChunks * 2
        )
    }

    private func buildResult(
        expandedQuery: ExpandedQuery,
        allResults: [HybridSearchResult],
        deduplicated: [HybridSearchResult],
        contextFiltered: [HybridSearchResult],
        reranked: [RankedChunk],
        finalChunks: [RankedChunk],
        formattedContext: String
    ) -> ContextualRetrievalResult {
        ContextualRetrievalResult(
            chunks: finalChunks.map { $0.chunk },
            formattedContext: formattedContext,
            retrievalMetadata: RetrievalMetadata(
                queriesUsed: expandedQuery.allQueries,
                totalCandidates: allResults.count,
                afterDeduplication: deduplicated.count,
                afterContextFilter: contextFiltered.count,
                afterReranking: reranked.count,
                finalSelected: finalChunks.count
            )
        )
    }


    private func selectDiverseChunks(
        chunks: [RankedChunk],
        maxCount: Int
    ) -> [RankedChunk] {
        var selected: [RankedChunk] = []
        var selectedFiles: Set<String> = []

        // First pass: select top chunk from each unique file
        for chunk in chunks {
            if !selectedFiles.contains(chunk.chunk.filePath) {
                selected.append(chunk)
                selectedFiles.insert(chunk.chunk.filePath)

                if selected.count >= maxCount {
                    return selected
                }
            }
        }

        // Second pass: fill remaining slots with highest scores
        for chunk in chunks {
            if selected.count >= maxCount { break }
            if !selected.contains(where: { $0.chunk.id == chunk.chunk.id }) {
                selected.append(chunk)
            }
        }

        return selected
    }

    private func formatContextWithMetadata(chunks: [RankedChunk]) -> String {
        chunks.enumerated().map { index, chunk in
            """
            ## Context [\(index + 1)/\(chunks.count)]: \(chunk.chunk.filePath)
            **Lines \(chunk.chunk.startLine)-\(chunk.chunk.endLine)** | **Relevance: \(String(format: "%.0f%%", chunk.finalScore * 100))**
            ```\(chunk.chunk.language.rawValue)
            \(chunk.chunk.content)
            ```
            """
        }.joined(separator: "\n\n")
    }

    private func deduplicateResults(
        _ results: [HybridSearchResult]
    ) -> [HybridSearchResult] {
        var seen: Set<UUID> = []
        var deduplicated: [HybridSearchResult] = []

        for result in results.sorted(by: { $0.hybridScore > $1.hybridScore }) {
            if !seen.contains(result.chunk.id) {
                seen.insert(result.chunk.id)
                deduplicated.append(result)
            }
        }

        return deduplicated
    }

}


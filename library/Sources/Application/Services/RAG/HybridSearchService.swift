import Foundation
import Domain

/// Hybrid search combining vector similarity and keyword matching (BM25)
/// Following Single Responsibility: Only handles hybrid search orchestration
/// SCALABLE: Database ranks ALL chunks, application fuses top-K results
/// SAFE: Enforces research-backed limits to prevent critical mass degradation
public struct HybridSearchService: Sendable {
    private let codebaseRepository: CodebaseRepositoryPort
    private let embeddingGenerator: EmbeddingGeneratorPort
    private let fullTextSearch: FullTextSearchPort
    private let criticalMassMonitor: RAGCriticalMassMonitor

    public init(
        codebaseRepository: CodebaseRepositoryPort,
        embeddingGenerator: EmbeddingGeneratorPort,
        fullTextSearch: FullTextSearchPort
    ) {
        self.codebaseRepository = codebaseRepository
        self.embeddingGenerator = embeddingGenerator
        self.fullTextSearch = fullTextSearch
        self.criticalMassMonitor = RAGCriticalMassMonitor()
    }

    /// Perform hybrid search with vector and keyword components
    /// Database searches ALL chunks and returns top-K for each method
    /// Application fuses the ranked results using RRF
    /// SAFE: Enforces critical mass limits to prevent quality degradation
    public func search(
        query: String,
        projectId: UUID,
        limit: Int = 10,
        alpha: Double = 0.7 // Weight: 0.7 = 70% semantic, 30% keyword
    ) async throws -> [HybridSearchResult] {
        // Evaluate and enforce critical mass limits
        let evaluation = criticalMassMonitor.evaluate(requestedCount: limit)

        // Log warnings if not in optimal zone
        for warning in evaluation.warnings {
            print("⚠️ [HybridSearch] \(warning)")
        }

        // Use enforced limit (may be lower than requested)
        let safeLimit = evaluation.enforcedLimit
        let candidateCount = safeLimit * 10

        // 1. Vector search: Database searches ALL chunks, returns top-K semantic
        let embedding = try await embeddingGenerator.generateEmbedding(text: query)
        let vectorResults = try await codebaseRepository.findSimilarChunks(
            projectId: projectId,
            queryEmbedding: embedding,
            limit: candidateCount,
            similarityThreshold: 0.5
        )

        // 2. Full-text search: Database searches ALL chunks, returns top-K BM25
        let keywordResults = try await performKeywordSearch(
            query: query,
            projectId: projectId,
            limit: candidateCount
        )

        // 3. RRF fusion: Combine rankings from both sources
        let fusedResults = fuseResults(
            vectorResults: vectorResults,
            keywordResults: keywordResults,
            alpha: alpha
        )

        // 4. Return top-K from fused results (using enforced limit)
        let finalResults = Array(fusedResults.prefix(safeLimit))

        // Log final count with zone indicator
        print("📊 [HybridSearch] Returning \(finalResults.count) chunks (zone: \(evaluation.zone.rawValue))")

        return finalResults
    }

    // MARK: - Private Methods

    /// Database-level full-text search with BM25 ranking
    /// PostgreSQL searches ALL chunks and returns top-K ranked by BM25
    private func performKeywordSearch(
        query: String,
        projectId: UUID,
        limit: Int
    ) async throws -> [KeywordSearchResult] {
        let fullTextResults = try await fullTextSearch.searchChunks(
            in: projectId,
            query: query,
            limit: limit,
            minScore: 0.01
        )

        return fullTextResults.map { result in
            KeywordSearchResult(
                chunk: result.chunk,
                bm25Score: Double(result.bm25Score)
            )
        }
    }

    /// Reciprocal Rank Fusion - combines rankings from multiple sources
    private func fuseResults(
        vectorResults: [SimilarCodeChunk],
        keywordResults: [KeywordSearchResult],
        alpha: Double
    ) -> [HybridSearchResult] {
        var fusedScores: [UUID: FusionScore] = [:]

        // Add vector scores with RRF
        for (rank, result) in vectorResults.enumerated() {
            let rrfScore = 1.0 / Double(rank + 60) // RRF constant k=60
            fusedScores[result.chunk.id, default: FusionScore(chunkId: result.chunk.id)].vectorScore = rrfScore
            fusedScores[result.chunk.id]?.chunk = result.chunk
            fusedScores[result.chunk.id]?.vectorSimilarity = Double(result.similarity)
        }

        // Add keyword scores with RRF
        for (rank, result) in keywordResults.enumerated() {
            let rrfScore = 1.0 / Double(rank + 60)
            fusedScores[result.chunk.id, default: FusionScore(chunkId: result.chunk.id)].keywordScore = rrfScore
            fusedScores[result.chunk.id]?.chunk = result.chunk
            fusedScores[result.chunk.id]?.bm25Score = result.bm25Score
        }

        // Calculate final weighted scores
        let results = fusedScores.values.compactMap { score -> HybridSearchResult? in
            guard let chunk = score.chunk else { return nil }

            let finalScore = (score.vectorScore * alpha) + (score.keywordScore * (1 - alpha))

            return HybridSearchResult(
                chunk: chunk,
                vectorSimilarity: score.vectorSimilarity,
                bm25Score: score.bm25Score,
                hybridScore: finalScore
            )
        }

        return results.sorted { $0.hybridScore > $1.hybridScore }
    }
}

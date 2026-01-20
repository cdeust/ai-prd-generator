import Foundation
import Domain

/// Verified reasoning execution with reliability assessment and RAG integration
/// Following Single Responsibility: Orchestrates verified reasoning pipeline
public struct ExecuteVerifiedReasoningUseCase: Sendable {
    private let aiProvider: AIProviderPort
    private let codebaseRepository: CodebaseRepositoryPort?
    private let embeddingGenerator: EmbeddingGeneratorPort?
    private let fullTextSearch: FullTextSearchPort?
    private let reliabilityAssessor: ReliabilityAssessor
    private let metricsCalculator: QualityMetricsCalculator
    private let reasoningRefiner: ReasoningRefiner
    private let trmEnhancement: TRMEnhancementService

    public init(
        aiProvider: AIProviderPort,
        codebaseRepository: CodebaseRepositoryPort? = nil,
        embeddingGenerator: EmbeddingGeneratorPort? = nil,
        fullTextSearch: FullTextSearchPort? = nil
    ) {
        self.aiProvider = aiProvider
        self.codebaseRepository = codebaseRepository
        self.embeddingGenerator = embeddingGenerator
        self.fullTextSearch = fullTextSearch
        self.reliabilityAssessor = ReliabilityAssessor()
        self.metricsCalculator = QualityMetricsCalculator()
        self.reasoningRefiner = ReasoningRefiner(aiProvider: aiProvider)
        self.trmEnhancement = TRMEnhancementService(aiProvider: aiProvider)
    }

    /// Execute verified reasoning with reliability assessment
    ///
    /// - Parameters:
    ///   - problem: Problem to reason about
    ///   - initialContext: Initial context (optional)
    ///   - constraints: Reasoning constraints (optional)
    ///   - codebaseId: Codebase for RAG retrieval (optional)
    ///   - reliabilityTarget: Target reliability score (0.5-1.0, default 0.95)
    ///   - maxRAGChunks: Maximum chunks to retrieve (1-20, default 8)
    ///   - maxReasoningHops: Maximum reasoning steps (1-10, default 5)
    public func execute(
        problem: String,
        initialContext: String = "",
        constraints: [String] = [],
        codebaseId: UUID? = nil,
        reliabilityTarget: Double = 0.95,
        maxRAGChunks: Int = 8,
        maxReasoningHops: Int = 5
    ) async throws -> VerifiedReasoningResult {
        let (context, retrievalMetadata) = try await performRAGRetrieval(
            problem: problem,
            initialContext: initialContext,
            codebaseId: codebaseId,
            maxChunks: maxRAGChunks
        )

        let verifiedChain = try await performMultiHopReasoning(
            problem: problem,
            context: context,
            constraints: constraints,
            maxHops: maxReasoningHops
        )

        let finalChain = try await refineIfNeeded(
            chain: verifiedChain,
            problem: problem,
            context: context,
            retrievalMetadata: retrievalMetadata,
            reliabilityTarget: reliabilityTarget
        )

        return buildResult(
            problem: problem,
            chain: finalChain.chain,
            retrievalMetadata: retrievalMetadata,
            iterations: finalChain.iterations
        )
    }

    // MARK: - Private Methods

    private func performRAGRetrieval(
        problem: String,
        initialContext: String,
        codebaseId: UUID?,
        maxChunks: Int
    ) async throws -> (context: String, retrievalMetadata: RetrievalMetadata?) {
        var currentContext = initialContext
        var retrievalMetadata: RetrievalMetadata?

        guard let codebaseId = codebaseId,
              let repo = codebaseRepository,
              let embedder = embeddingGenerator,
              let fts = fullTextSearch else {
            return (currentContext, nil)
        }

        let ragOrchestrator = createRAGOrchestrator(repo: repo, embedder: embedder, fts: fts)
        let retrieval = try await ragOrchestrator.retrieve(
            query: problem,
            projectId: codebaseId,
            currentContext: currentContext,
            maxChunks: maxChunks
        )

        currentContext += "\n\n" + retrieval.formattedContext
        retrievalMetadata = retrieval.retrievalMetadata

        return (currentContext, retrievalMetadata)
    }

    private func createRAGOrchestrator(
        repo: CodebaseRepositoryPort,
        embedder: EmbeddingGeneratorPort,
        fts: FullTextSearchPort
    ) -> ContextRetrievalOrchestrator {
        ContextRetrievalOrchestrator(
            hybridSearch: HybridSearchService(
                codebaseRepository: repo,
                embeddingGenerator: embedder,
                fullTextSearch: fts
            ),
            queryExpander: QueryExpansionService(aiProvider: aiProvider),
            reranker: RerankingService(aiProvider: aiProvider),
            aiProvider: aiProvider
        )
    }

    private func performMultiHopReasoning(
        problem: String,
        context: String,
        constraints: [String],
        maxHops: Int
    ) async throws -> VerifiedThoughtChain {
        let reasoningEngine = MultiHopReasoningEngine(aiProvider: aiProvider)
        return try await reasoningEngine.reason(
            problem: problem,
            context: context,
            constraints: constraints,
            maxHops: maxHops
        )
    }

    private func refineIfNeeded(
        chain: VerifiedThoughtChain,
        problem: String,
        context: String,
        retrievalMetadata: RetrievalMetadata?,
        reliabilityTarget: Double
    ) async throws -> (chain: VerifiedThoughtChain, iterations: Int) {
        let initialReliability = reliabilityAssessor.assess(
            verifiedChain: chain,
            retrievalMetadata: retrievalMetadata
        )

        guard initialReliability.score < reliabilityTarget else {
            return (chain, 0)
        }

        let refiner: Refiner<VerifiedThoughtChain> = { previousChain, prob, ctx in
            let reliability = self.reliabilityAssessor.assess(
                verifiedChain: previousChain,
                retrievalMetadata: retrievalMetadata
            )

            return try await self.reasoningRefiner.refine(
                chain: previousChain,
                problem: prob,
                context: ctx,
                issues: reliability.issues
            )
        }

        // Use balanced policy with custom quality target
        let policy = try! AdaptiveHaltingPolicy(
            minConvergenceProbability: 0.75,
            maxIterations: 5,
            targetQuality: reliabilityTarget
        )
        let config = TRMConfig(policy: policy, calibrateConfidence: false)

        let enhanced = try await trmEnhancement.enhance(
            baseResult: chain,
            problem: problem,
            context: context,
            refiner: refiner,
            config: config
        )

        return (enhanced.result, enhanced.iterationsPerformed)
    }

    private func buildResult(
        problem: String,
        chain: VerifiedThoughtChain,
        retrievalMetadata: RetrievalMetadata?,
        iterations: Int
    ) -> VerifiedReasoningResult {
        let reliability = reliabilityAssessor.assess(
            verifiedChain: chain,
            retrievalMetadata: retrievalMetadata
        )

        return VerifiedReasoningResult(
            problem: problem,
            conclusion: chain.conclusion,
            confidence: chain.confidence,
            reliabilityScore: reliability.score,
            verifiedChain: chain,
            retrievalMetadata: retrievalMetadata,
            iterationsNeeded: iterations,
            qualityMetrics: metricsCalculator.calculate(
                chain: chain,
                reliabilityScore: reliability.score
            )
        )
    }
}

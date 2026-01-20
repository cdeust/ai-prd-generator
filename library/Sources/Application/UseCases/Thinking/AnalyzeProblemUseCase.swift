import Foundation
import Domain

/// Use case for chain-of-thought problem analysis with RAG integration
///
/// **Professional Design:**
/// - TRM-powered refinement with intelligent halting
/// - Configurable quality thresholds and iteration limits
/// - Convergence detection instead of arbitrary limits
///
/// Single Responsibility: Execute structured analysis of problem domain
public struct AnalyzeProblemUseCase: Sendable {
    private let aiProvider: AIProviderPort
    private let promptBuilder: StructuredCoTPromptBuilder
    private let responseParser: StructuredCoTParser
    private let trmEnhancement: TRMEnhancementService
    private let thoughtChainRefiner: ThoughtChainRefiner
    private let ragRetriever: CoTRAGRetriever?

    public init(
        aiProvider: AIProviderPort,
        codebaseRepository: CodebaseRepositoryPort? = nil,
        embeddingGenerator: EmbeddingGeneratorPort? = nil,
        fullTextSearch: FullTextSearchPort? = nil
    ) {
        self.aiProvider = aiProvider
        self.promptBuilder = StructuredCoTPromptBuilder()
        self.responseParser = StructuredCoTParser()
        self.trmEnhancement = TRMEnhancementService(aiProvider: aiProvider)
        self.thoughtChainRefiner = ThoughtChainRefiner(aiProvider: aiProvider)

        if codebaseRepository != nil && embeddingGenerator != nil && fullTextSearch != nil {
            self.ragRetriever = CoTRAGRetriever(
                aiProvider: aiProvider,
                codebaseRepository: codebaseRepository,
                embeddingGenerator: embeddingGenerator,
                fullTextSearch: fullTextSearch
            )
        } else {
            self.ragRetriever = nil
        }
    }

    /// Execute reasoning with optional RAG integration
    ///
    /// **Professional Parameters:**
    /// - `qualityTarget`: Target confidence score (0.5-1.0, default 0.85)
    /// - `config`: TRM configuration for intelligent halting (optional)
    ///
    /// **Behavior:**
    /// - Uses TRM enhancement for convergence detection when config provided
    /// - Halts on oscillation or diminishing returns
    /// - More efficient than fixed iteration limits
    public func execute(
        problem: String,
        context: String? = nil,
        constraints: [String] = [],
        useSelfConsistency: Bool = false,
        codebaseId: UUID? = nil,
        qualityTarget: Double = 0.85,
        config: TRMConfig? = nil
    ) async throws -> ThoughtChain {
        var enrichedContext = context ?? ""

        // Enrich with codebase context using advanced RAG
        if let codebaseId = codebaseId {
            let ragContext = try await retrieveWithRAG(
                query: problem,
                codebaseId: codebaseId,
                baseContext: context ?? ""
            )
            enrichedContext += "\n\n## Relevant Codebase Context\n\n\(ragContext)"
        }

        // Generate initial reasoning
        let initialChain: ThoughtChain
        if useSelfConsistency {
            initialChain = try await reasonWithSelfConsistency(
                problem: problem,
                context: enrichedContext,
                constraints: constraints
            )
        } else {
            initialChain = try await reasonSinglePath(
                problem: problem,
                context: enrichedContext,
                constraints: constraints
            )
        }

        // Use TRM enhancement if config provided and below quality target
        if let config = config, initialChain.confidence < qualityTarget {
            return try await applyTRMEnhancement(
                to: initialChain,
                problem: problem,
                context: enrichedContext,
                constraints: constraints,
                config: config
            )
        }

        return initialChain
    }

    // MARK: - Private Methods

    private func reasonSinglePath(
        problem: String,
        context: String,
        constraints: [String]
    ) async throws -> ThoughtChain {
        // Use structured CoT prompt
        let prompt = promptBuilder.buildPrompt(
            problem: problem,
            context: context,
            constraints: constraints
        )

        let response = try await aiProvider.generateText(
            prompt: prompt,
            temperature: 0.7
        )

        // Parse structured response
        let parsed = responseParser.parse(response)

        return ThoughtChain(
            id: UUID(),
            problem: problem,
            thoughts: parsed.thoughts,
            conclusion: parsed.conclusion,
            confidence: parsed.confidence,
            alternatives: [],
            assumptions: parsed.assumptions,
            timestamp: Date()
        )
    }

    private func reasonWithSelfConsistency(
        problem: String,
        context: String,
        constraints: [String]
    ) async throws -> ThoughtChain {
        let numPaths = 3
        var chains: [ThoughtChain] = []

        for pathNumber in 0..<numPaths {
            // Use different reasoning styles for diversity
            let prompt = promptBuilder.buildSelfConsistencyPrompt(
                problem: problem,
                context: context,
                constraints: constraints,
                pathNumber: pathNumber
            )

            let response = try await aiProvider.generateText(
                prompt: prompt,
                temperature: 0.8 // Higher temp for diversity
            )

            let parsed = responseParser.parse(response)

            chains.append(ThoughtChain(
                id: UUID(),
                problem: problem,
                thoughts: parsed.thoughts,
                conclusion: parsed.conclusion,
                confidence: parsed.confidence,
                alternatives: [],
                assumptions: parsed.assumptions,
                timestamp: Date()
            ))
        }

        return selectMostConsistent(chains: chains)
    }

    private func selectMostConsistent(chains: [ThoughtChain]) -> ThoughtChain {
        var groups: [String: [ThoughtChain]] = [:]

        for chain in chains {
            let normalized = normalizeConclusion(chain.conclusion)
            groups[normalized, default: []].append(chain)
        }

        let largestGroup = groups.max { $0.value.count < $1.value.count }

        if let group = largestGroup?.value,
           let best = group.max(by: { $0.confidence < $1.confidence }) {
            let consistencyBonus = Double(group.count) / Double(chains.count) * 0.2

            return ThoughtChain(
                id: best.id,
                problem: best.problem,
                thoughts: best.thoughts,
                conclusion: best.conclusion,
                confidence: min(1.0, best.confidence + consistencyBonus),
                alternatives: best.alternatives,
                assumptions: best.assumptions,
                timestamp: best.timestamp
            )
        }

        return chains.max { $0.confidence < $1.confidence } ?? chains[0]
    }

    private func normalizeConclusion(_ conclusion: String) -> String {
        conclusion
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Apply TRM enhancement for intelligent iterative refinement
    ///
    /// **3R's Justification - Readability & Reusability:**
    /// - Readability: Encapsulates closure definition complexity
    /// - Reusability: Standard pattern for TRM-enhancing CoT
    /// - Testable: Can test enhancement behavior in isolation
    private func applyTRMEnhancement(
        to initialChain: ThoughtChain,
        problem: String,
        context: String,
        constraints: [String],
        config: TRMConfig
    ) async throws -> ThoughtChain {
        let refiner: Refiner<ThoughtChain> = { previousChain, prob, ctx in
            try await self.refineThoughtChain(
                previousChain: previousChain,
                problem: prob,
                context: ctx,
                constraints: constraints
            )
        }

        let enhanced = try await trmEnhancement.enhance(
            baseResult: initialChain,
            problem: problem,
            context: context,
            refiner: refiner,
            config: config
        )

        return enhanced.result
    }

    /// Refine ThoughtChain using ThoughtChainRefiner service
    ///
    /// **3R's Justification - Reusability:**
    /// - Delegates to reusable ThoughtChainRefiner service
    /// - Testable through service interface
    private func refineThoughtChain(
        previousChain: ThoughtChain,
        problem: String,
        context: String,
        constraints: [String]
    ) async throws -> ThoughtChain {
        return try await thoughtChainRefiner.refine(
            previousChain: previousChain,
            problem: problem,
            context: context,
            constraints: constraints
        )
    }

    /// RAG retrieval orchestration
    private func retrieveWithRAG(
        query: String,
        codebaseId: UUID,
        baseContext: String
    ) async throws -> String {
        guard let retriever = ragRetriever else { return "" }
        return try await retriever.retrieveContext(
            query: query,
            codebaseId: codebaseId,
            baseContext: baseContext
        )
    }
}


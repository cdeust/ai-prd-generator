import Foundation
import Domain

/// Service for building enriched context for PRD generation
///
/// Orchestrates RAG, reasoning, and vision analysis to create
/// comprehensive context for intelligent PRD generation.
public actor EnrichedContextBuilder {
    let hybridSearch: HybridSearchService?
    let reasoningOrchestrator: ThinkingOrchestratorUseCase?
    let visionAnalyzer: VisionAnalysisPort?
    let mockupRepository: MockupRepositoryPort?
    let codebaseRepository: CodebaseRepositoryPort?
    let intelligenceTracker: IntelligenceTrackerService?
    let uploadsDirectory: URL
    let formatter = EnrichedContextFormatter()

    public init(
        hybridSearch: HybridSearchService? = nil,
        reasoningOrchestrator: ThinkingOrchestratorUseCase? = nil,
        visionAnalyzer: VisionAnalysisPort? = nil,
        mockupRepository: MockupRepositoryPort? = nil,
        codebaseRepository: CodebaseRepositoryPort? = nil,
        intelligenceTracker: IntelligenceTrackerService? = nil
    ) {
        self.hybridSearch = hybridSearch
        self.reasoningOrchestrator = reasoningOrchestrator
        self.visionAnalyzer = visionAnalyzer
        self.mockupRepository = mockupRepository
        self.codebaseRepository = codebaseRepository
        self.intelligenceTracker = intelligenceTracker
        self.uploadsDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ai-prd-uploads", isDirectory: true)
    }

    /// Build enriched context from multiple intelligence sources
    /// Returns FULL context (not aggregated) - sections will extract what they need
    public func buildContext(
        request: PRDRequest,
        codebaseId: UUID?,
        prdId: UUID? = nil
    ) async throws -> EnrichedPRDContext {
        async let codeContext = gatherCodebaseContext(codebaseId, request, prdId: prdId)
        async let reasoningContext = gatherReasoningContext(request)
        async let visionContext = gatherVisionContext(request)

        let (code, reasoning, vision) = try await (codeContext, reasoningContext, visionContext)

        return EnrichedPRDContext(
            baseRequest: request,
            ragResults: code,
            reasoningPlan: reasoning,
            visionResults: vision,
            aggregatedContext: "" // No longer pre-aggregate - extract per section
        )
    }

    /// Build section-specific enriched context (multi-pass approach)
    public func buildSectionContext(
        for sectionType: SectionType,
        from enrichedContext: EnrichedPRDContext
    ) -> String {
        switch sectionType {
        case .overview, .goals:
            return buildHighLevelContext(enrichedContext)
        case .requirements, .acceptanceCriteria:
            return buildRequirementsContext(enrichedContext)
        case .technicalSpecification, .apiSpecification, .dataModel:
            return buildTechnicalContext(enrichedContext)
        case .userStories:
            return buildUserStoriesContext(enrichedContext)
        default:
            return buildBalancedContext(enrichedContext)
        }
    }

    private func buildHighLevelContext(_ ctx: EnrichedPRDContext) -> String {
        var result = formatter.formatReasoningOnly(ctx.reasoningPlan)
        let vision = formatter.formatVisionSummary(ctx.visionResults)
        if !vision.isEmpty { result += "\n\n" + vision }
        return result
    }

    private func buildRequirementsContext(_ ctx: EnrichedPRDContext) -> String {
        var result = formatter.formatReasoningOnly(ctx.reasoningPlan)
        let vision = formatter.formatVisionResults(ctx.visionResults)
        if !vision.isEmpty { result += "\n\n" + vision }
        if let code = ctx.ragResults { result += "\n\n" + formatter.formatCodeSummary(code, maxChunks: 2) }
        return result
    }

    private func buildTechnicalContext(_ ctx: EnrichedPRDContext) -> String {
        var result = ctx.ragResults.map { formatter.formatCodeDetailed($0, maxChunks: 5) } ?? ""
        let vision = formatter.formatVisionResults(ctx.visionResults)
        if !vision.isEmpty { result += "\n\n" + vision }
        if let reasoning = ctx.reasoningPlan { result += "\n\n" + formatter.formatTechnicalDecisions(reasoning) }
        return result
    }

    private func buildUserStoriesContext(_ ctx: EnrichedPRDContext) -> String {
        var result = formatter.formatUserFocusedReasoning(ctx.reasoningPlan)
        let vision = formatter.formatVisionResults(ctx.visionResults)
        if !vision.isEmpty { result += "\n\n" + vision }
        return result
    }

    private func buildBalancedContext(_ ctx: EnrichedPRDContext) -> String {
        var result = formatter.formatReasoningOnly(ctx.reasoningPlan)
        let vision = formatter.formatVisionSummary(ctx.visionResults)
        if !vision.isEmpty { result += "\n\n" + vision }
        if let code = ctx.ragResults { result += "\n\n" + formatter.formatCodeSummary(code, maxChunks: 1) }
        return result
    }

    private func gatherCodebaseContext(
        _ codebaseId: UUID?,
        _ request: PRDRequest,
        prdId: UUID?
    ) async throws -> RAGSearchResults? {
        guard let id = codebaseId,
              let search = hybridSearch,
              let repo = codebaseRepository else {
            return nil
        }

        // Look up the project ID from the codebase - chunks are indexed under projectId
        let projects = try await repo.listProjects(limit: 100, offset: 0)
        guard let project = projects.first(where: { $0.codebaseId == id }) else {
            print("⚠️ No indexed project found for codebase \(id)")
            return nil
        }

        print("🔍 Searching indexed project \(project.id) for codebase \(id)")

        let results = try await search.search(
            query: request.description,
            projectId: project.id,
            limit: 10
        )

        print("📚 Found \(results.count) relevant code chunks")

        // Track RAG retrieval in intelligence layer (prdId may be nil, updated later via upsert)
        if let tracker = intelligenceTracker, !results.isEmpty {
            do {
                try await trackRAGRetrieval(
                    prdId: prdId,
                    codebaseId: id,
                    query: request.description,
                    results: results,
                    tracker: tracker
                )
            } catch {
                print("❌ [Intelligence] Failed to track RAG retrieval: \(error)")
            }
        }

        return RAGSearchResults(
            relevantFiles: results.map(\.chunk.filePath),
            relevantChunks: results.map(\.chunk.content),
            averageRelevanceScore: results.map(\.hybridScore)
                .reduce(0, +) / Double(max(results.count, 1))
        )
    }

    private func trackRAGRetrieval(
        prdId: UUID?,
        codebaseId: UUID,
        query: String,
        results: [HybridSearchResult],
        tracker: IntelligenceTrackerService
    ) async throws {
        let retrievedChunks = results.map { result in
            RetrievedChunk(
                chunkId: result.chunk.id,
                filePath: result.chunk.filePath,
                score: result.hybridScore,
                content: String(result.chunk.content.prefix(500)),
                metadata: ["vector": String(format: "%.3f", result.vectorSimilarity ?? 0),
                          "bm25": String(format: "%.3f", result.bm25Score ?? 0)]
            )
        }

        _ = try await tracker.trackRAGRetrieval(
            prdId: prdId,
            codebaseId: codebaseId,
            query: query,
            queryType: .semantic,
            retrievedChunks: retrievedChunks,
            retrievalMethod: .hybrid,
            reasoningForSelection: "Hybrid search (semantic + BM25) for PRD context"
        )
        let prdInfo = prdId.map { "\($0)" } ?? "pending"
        print("✅ [Intelligence] Tracked RAG retrieval: \(results.count) chunks (PRD: \(prdInfo))")
    }

    private func gatherReasoningContext(
        _ request: PRDRequest
    ) async throws -> ReasoningPlan? {
        guard let orchestrator = reasoningOrchestrator else {
            return nil
        }

        let problem = buildReasoningPrompt(from: request)
        let result = try await orchestrator.execute(
            problem: problem,
            preferredStrategy: .chainOfThought
        )

        return ReasoningPlan(
            steps: formatter.extractSteps(from: result),
            keyDecisions: formatter.extractDecisions(from: result),
            confidence: result.confidence
        )
    }

    func buildReasoningPrompt(from request: PRDRequest) -> String {
        """
        Analyze this PRD request and plan the document structure:

        Title: \(request.title)
        Description: \(request.description)

        Requirements:
        \(request.requirements.map { "- \($0)" }.joined(separator: "\n"))

        Think through:
        1. What are the key goals and success criteria?
        2. What functional/non-functional requirements are implied?
        3. What technical decisions need to be made?
        4. What user stories would be valuable?
        5. What risks should be considered?

        Provide a structured analysis.
        """
    }

}

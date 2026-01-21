import Foundation
import Domain

/// Use case for generating a PRD section-by-section with budget-aware context selection
///
/// Flow:
/// 1. LLM analyzes input (title, description, mockups, codebase) → tracks to DB
/// 2. LLM generates clarification questions → sends via interactionHandler
/// 3. User answers → LLM re-analyzes with answers → loop until no more questions
/// 4. LLM selects optimal strategy per section based on DB entries
/// 5. PRD generation starts section by section
public struct GeneratePRDUseCase: Sendable {
    let aiProvider: AIProviderPort
    let prdRepository: PRDRepositoryPort
    let templateRepository: PRDTemplateRepositoryPort
    let contextService: PRDContextService
    let sectionGeneration: SectionGeneration
    let jiraGenerator: ChunkedJiraGenerator
    let traceUpdater: Phase1TraceUpdater
    let intelligenceTracker: IntelligenceTrackerService?
    let interactionHandler: UserInteractionPort?
    let requirementAnalyzer: RequirementAnalyzerService?

    public init(
        aiProvider: AIProviderPort,
        prdRepository: PRDRepositoryPort,
        templateRepository: PRDTemplateRepositoryPort,
        codebaseRepository: CodebaseRepositoryPort? = nil,
        embeddingGenerator: EmbeddingGeneratorPort? = nil,
        mockupRepository: MockupRepositoryPort? = nil,
        promptService: PromptEngineeringService? = nil,
        tokenizer: TokenizerPort? = nil,
        compressor: AppleIntelligenceContextCompressor? = nil,
        contextExtractor: SectionContextExtractor,
        contextBuilder: EnrichedContextBuilder? = nil,
        requirementAnalyzer: RequirementAnalyzerService? = nil,
        interactionHandler: UserInteractionPort? = nil,
        thinkingOrchestrator: ThinkingOrchestratorUseCase? = nil,
        intelligenceTracker: IntelligenceTrackerService? = nil,
        coherenceScorer: QuestionCoherenceScorer? = nil,
        verificationService: ChainOfVerificationService? = nil,
        llmVerifier: LLMResponseVerifier? = nil
    ) {
        self.aiProvider = aiProvider
        self.prdRepository = prdRepository
        self.templateRepository = templateRepository
        self.interactionHandler = interactionHandler
        self.requirementAnalyzer = requirementAnalyzer
        self.intelligenceTracker = intelligenceTracker

        // Use provided verifier (DRY - created once in factory with 80% threshold)
        let verifier = llmVerifier ?? LLMResponseVerifier(
            verificationService: verificationService,
            intelligenceTracker: intelligenceTracker,
            verificationThreshold: 0.8
        )

        self.jiraGenerator = ChunkedJiraGenerator(
            aiProvider: aiProvider,
            tokenizer: tokenizer,
            verifier: verifier
        )

        let mockupAssociation = mockupRepository.map { MockupAssociationService(repository: $0) }
        self.traceUpdater = Phase1TraceUpdater(
            intelligenceTracker: intelligenceTracker,
            mockupAssociation: mockupAssociation
        )

        let clarificationEnrichment = interactionHandler.map {
            ClarificationEnrichment(handler: $0, intelligenceTracker: intelligenceTracker)
        }
        self.contextService = PRDContextService(
            contextBuilder: contextBuilder,
            clarificationEnrichment: clarificationEnrichment,
            requirementAnalyzer: requirementAnalyzer,
            coherenceScorer: coherenceScorer,
            intelligenceTracker: intelligenceTracker,
            verificationService: verificationService
        )

        let sectionClarificationService = SectionClarificationService(aiProvider: aiProvider)
        self.sectionGeneration = SectionGeneration(
            aiProvider: aiProvider,
            promptBuilder: PRDPromptBuilder(
                promptService: promptService,
                tokenizer: tokenizer,
                compressor: compressor
            ),
            contextExtractor: contextExtractor,
            contextBuilder: contextBuilder,
            clarificationService: sectionClarificationService,
            interactionHandler: interactionHandler,
            thinkingOrchestrator: thinkingOrchestrator,
            intelligenceTracker: intelligenceTracker,
            verificationService: verificationService,
            llmVerifier: verifier
        )
    }

    /// Execute multi-pass PRD generation with streaming
    public func execute(
        _ request: PRDRequest,
        onChunk: @escaping (String) async throws -> Void = { _ in },
        onProgress: @escaping (String) async throws -> Void = { _ in }
    ) async throws -> PRDDocument {
        try request.validate()
        intelligenceTracker?.startGeneration()

        // PHASE 1: ANALYSIS
        try await onProgress("Analyzing your request...")
        print("🔬 PHASE 1: Analysis starting")

        let enrichedContext = try await contextService.buildEnrichedContext(for: request, prdId: nil)
        print("📊 [Phase 1] Context ready - RAG: \(enrichedContext?.ragResults?.relevantFiles.count ?? 0) files")
        print("🖼️ [Phase 1] Vision results: \(enrichedContext?.visionResults?.count ?? 0) mockups analyzed")

        // Extract mockup summaries for clarification questions
        let mockupSummaries = extractMockupSummaries(from: enrichedContext?.visionResults)

        let clarificationResult = try await contextService.enrichRequestWithClarifications(
            request,
            codebaseContext: enrichedContext?.ragResults,
            mockupSummaries: mockupSummaries
        )

        let analysisRequest = createAnalysisRequest(from: clarificationResult)
        try await onProgress("✅ Analysis complete. Starting PRD generation...")
        print("✨ PHASE 1 complete - \(clarificationResult.answeredQuestionIds.count) questions answered")

        // PHASE 2: GENERATION
        try await onProgress("Generating PRD document...")
        print("📝 PHASE 2: Generation starting")

        let initialDocument = createInitialDocument(for: analysisRequest)
        var savedDocument = try await prdRepository.save(initialDocument)
        print("📝 Created draft PRD document: \(savedDocument.id)")

        await traceUpdater.updateTraces(
            prdId: savedDocument.id,
            codebaseId: analysisRequest.codebaseId,
            mockupFileIds: analysisRequest.mockupFileIds,
            clarificationQuestionIds: analysisRequest.phase1QuestionIds ?? []
        )

        let documentId = savedDocument.id
        let userId = analysisRequest.userId
        var usedStrategies: [ThinkingStrategy] = []

        let allSections = try await sectionGeneration.generateAllSections(
            request: analysisRequest,
            prdId: documentId,
            enrichedContext: enrichedContext,
            onChunk: onChunk,
            onSectionComplete: { [prdRepository, self] (_, allSectionsSoFar, strategy, trackingMetadata: SectionTrackingMetadata?) in
                if let strategy = strategy { usedStrategies.append(strategy) }
                let strategyString = mostCommonStrategy(from: usedStrategies)
                let approach = buildApproachString(sectionCount: allSectionsSoFar.count, hasEnrichedContext: enrichedContext != nil)

                let updatedDocument = PRDDocument(
                    id: documentId,
                    userId: userId,
                    title: analysisRequest.title,
                    description: analysisRequest.description.isEmpty ? nil : analysisRequest.description,
                    status: .draft,
                    privacyLevel: analysisRequest.privacyLevel,
                    sections: allSectionsSoFar,
                    metadata: DocumentMetadata(
                        author: "AI PRD Builder",
                        projectName: analysisRequest.title,
                        aiProvider: aiProvider.providerName,
                        generationApproach: approach,
                        codebaseId: analysisRequest.codebaseId,
                        thinkingStrategy: strategyString
                    )
                )

                _ = try await prdRepository.update(updatedDocument)
                print("💾 Saved progress: \(allSectionsSoFar.count) sections, strategy: \(strategyString ?? "none")")

                // NOW persist tracking data AFTER sections are saved to database
                if let metadata = trackingMetadata {
                    await self.persistSectionTracking(metadata)
                }
            }
        )

        let finalStrategy = mostCommonStrategy(from: usedStrategies)
        savedDocument = try await updateDocumentSections(
            documentId: savedDocument.id,
            userId: analysisRequest.userId,
            sections: allSections,
            enrichedContext: enrichedContext,
            request: analysisRequest,
            thinkingStrategy: finalStrategy
        )

        let finalDocument = try await createFinalDocument(
            documentId: savedDocument.id,
            from: analysisRequest,
            sections: allSections,
            enrichedContext: enrichedContext,
            thinkingStrategy: finalStrategy,
            onChunk: onChunk
        )

        let result = try await prdRepository.update(finalDocument)
        try? await intelligenceTracker?.finalizeMetrics(prdId: result.id, strategyUsed: finalStrategy)

        // NOTE: Clarification effectiveness is evaluated BEFORE asking (threshold 0.8 against feature description)
        // Post-PRD evaluation is not needed - if a question was asked, its answer MUST be used in the PRD

        print("✨ PRD generation complete and saved!")
        return result
    }

    private func persistSectionTracking(_ metadata: SectionTrackingMetadata) async {
        // Persist LLM interaction tracking AFTER section is saved to database
        // This avoids foreign key constraint violations
        do {
            let strategy = ThinkingStrategyStringConverter.toString(metadata.strategy)
            _ = try await intelligenceTracker?.trackLLMInteraction(
                prdId: metadata.prdId,
                sectionId: metadata.sectionId,
                purpose: .sectionGeneration,
                promptTemplate: "Section template",
                actualPrompt: metadata.prompt,
                llmModel: aiProvider.providerName,
                provider: aiProvider.providerName,
                response: metadata.content,
                latencyMs: metadata.latencyMs,
                thinkingStrategy: strategy
            )
            print("✅ [Intelligence] Tracked section generation for \(metadata.sectionType.displayName)")
        } catch {
            print("⚠️ [Intelligence] LLM tracking failed (non-fatal): \(error)")
        }
    }
}

import Foundation
import Domain

/// Handles generation of individual PRD sections with continuous clarification
struct SectionGeneration: Sendable {
    private let aiProvider: AIProviderPort
    private let promptBuilder: PRDPromptBuilder
    private let contextExtractor: SectionContextExtractor
    private let contextBuilder: EnrichedContextBuilder?
    private let clarificationService: SectionClarificationService?
    private let interactionHandler: UserInteractionPort?
    private let thinkingOrchestrator: ThinkingOrchestratorUseCase?
    private let strategyRecommender: StrategyRecommendationService
    private let intelligenceTracker: IntelligenceTrackerService?
    private let llmTracker: SectionLLMTracker
    private let xmlBuilder = ClarificationXMLBuilder()
    private let contentGenerator: SectionContentGenerator
    private let clarificationCollector: SectionClarificationCollector

    init(
        aiProvider: AIProviderPort,
        promptBuilder: PRDPromptBuilder,
        contextExtractor: SectionContextExtractor,
        contextBuilder: EnrichedContextBuilder?,
        clarificationService: SectionClarificationService? = nil,
        interactionHandler: UserInteractionPort? = nil,
        thinkingOrchestrator: ThinkingOrchestratorUseCase? = nil,
        intelligenceTracker: IntelligenceTrackerService? = nil
    ) {
        self.aiProvider = aiProvider
        self.promptBuilder = promptBuilder
        self.contextExtractor = contextExtractor
        self.contextBuilder = contextBuilder
        self.clarificationService = clarificationService
        self.interactionHandler = interactionHandler
        self.thinkingOrchestrator = thinkingOrchestrator
        self.intelligenceTracker = intelligenceTracker
        self.strategyRecommender = StrategyRecommendationService(
            aiProvider: aiProvider,
            intelligenceTracker: intelligenceTracker
        )
        self.llmTracker = SectionLLMTracker(
            intelligenceTracker: intelligenceTracker,
            aiProvider: aiProvider
        )
        self.contentGenerator = SectionContentGenerator(
            aiProvider: aiProvider,
            thinkingOrchestrator: thinkingOrchestrator,
            llmTracker: llmTracker
        )
        self.clarificationCollector = SectionClarificationCollector(
            clarificationService: clarificationService,
            interactionHandler: interactionHandler,
            llmTracker: llmTracker
        )
    }

    private static let sectionTypes: [SectionType] = [
        .overview, .goals, .requirements, .userStories, .technicalSpecification, .acceptanceCriteria
    ]

    func generateAllSections(
        request: PRDRequest,
        prdId: UUID,
        enrichedContext: EnrichedPRDContext?,
        onChunk: @escaping (String) async throws -> Void,
        onSectionComplete: ((PRDSection, [PRDSection], ThinkingStrategy?, SectionTrackingMetadata?) async throws -> Void)? = nil
    ) async throws -> [PRDSection] {
        logGenerationStart(request)

        var sections: [PRDSection] = []
        var clarifications: String = ""

        for (index, sectionType) in Self.sectionTypes.enumerated() {
            let result = try await generateSingleSection(
                index: index,
                sectionType: sectionType,
                request: request,
                prdId: prdId,
                enrichedContext: enrichedContext,
                previousSections: sections,
                clarifications: clarifications,
                onChunk: onChunk
            )
            sections.append(result.section)
            clarifications = result.updatedClarifications
            try await onSectionComplete?(result.section, sections, result.strategy, result.trackingMetadata)
        }

        return sections
    }

    private func generateSingleSection(
        index: Int,
        sectionType: SectionType,
        request: PRDRequest,
        prdId: UUID,
        enrichedContext: EnrichedPRDContext?,
        previousSections: [PRDSection],
        clarifications: String,
        onChunk: @escaping (String) async throws -> Void
    ) async throws -> SectionGenerationResult {
        print("⏳ [\(index + 1)/\(Self.sectionTypes.count)] Generating \(sectionType.displayName)...")

        let sectionClarifications = try await clarificationCollector.askClarifications(
            prdId: prdId,
            sectionType: sectionType,
            request: request,
            previousSections: previousSections
        )
        let updatedClarifications = clarifications + sectionClarifications

        if index > 0 { try await onChunk("\n\n") }
        try await onChunk("# \(sectionType.displayName)\n\n")

        let enrichedRequest = xmlBuilder.enrichRequest(request, withClarifications: updatedClarifications)
        let (section, strategy, trackingMetadata) = try await generateSection(
            sectionType: sectionType,
            order: index,
            request: enrichedRequest,
            prdId: prdId,
            enrichedContext: enrichedContext,
            onChunk: onChunk
        )

        print("✅ [\(index + 1)/\(Self.sectionTypes.count)] \(sectionType.displayName) complete")
        return SectionGenerationResult(
            section: section,
            updatedClarifications: updatedClarifications,
            strategy: strategy,
            trackingMetadata: trackingMetadata
        )
    }

    private func logGenerationStart(_ request: PRDRequest) {
        print("🚀 PRD generation: \(Self.sectionTypes.count) sections, \(request.description.count) chars")
    }

    func generateSection(
        sectionType: SectionType,
        order: Int,
        request: PRDRequest,
        prdId: UUID,
        enrichedContext: EnrichedPRDContext?,
        onChunk: @escaping (String) async throws -> Void
    ) async throws -> (section: PRDSection, strategy: ThinkingStrategy?, trackingMetadata: SectionTrackingMetadata?) {
        let sectionId = UUID()
        let startTime = Date()

        let strategy = try await selectAndTrackStrategy(
            prdId: prdId,
            sectionId: sectionId,
            sectionType: sectionType,
            request: request,
            enrichedContext: enrichedContext
        )

        let (content, prompt) = try await buildSectionContent(
            sectionType: sectionType,
            prdId: prdId,
            sectionId: sectionId,
            request: request,
            enrichedContext: enrichedContext,
            strategy: strategy,
            onChunk: onChunk
        )

        let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)

        // Create final section
        let section = PRDSection(
            id: sectionId,
            type: sectionType,
            title: sectionType.displayName,
            content: content,
            order: order,
            thinkingStrategy: ThinkingStrategyStringConverter.toString(strategy)
        )

        // Create tracking metadata to be persisted AFTER section is saved to database
        let trackingMetadata = SectionTrackingMetadata(
            sectionId: sectionId,
            prdId: prdId,
            sectionType: sectionType,
            strategy: strategy,
            prompt: prompt,
            content: content,
            latencyMs: latencyMs
        )

        return (section, strategy, trackingMetadata)
    }

    private func selectAndTrackStrategy(
        prdId: UUID,
        sectionId: UUID,
        sectionType: SectionType,
        request: PRDRequest,
        enrichedContext: EnrichedPRDContext?
    ) async throws -> ThinkingStrategy {
        let hasCodebase = enrichedContext != nil
        let strategy = try await selectStrategyForSection(
            prdId: prdId,
            sectionType: sectionType,
            request: request,
            hasCodebase: hasCodebase
        )

        print("🎯 Selected strategy: \(strategy) for \(sectionType.displayName)")

        do {
            try await trackStrategyDecision(
                prdId: prdId,
                sectionId: sectionId,
                strategy: strategy,
                sectionType: sectionType
            )
        } catch {
            print("⚠️ Failed to track strategy decision: \(error)")
        }

        return strategy
    }

    private func buildSectionContent(
        sectionType: SectionType,
        prdId: UUID,
        sectionId: UUID,
        request: PRDRequest,
        enrichedContext: EnrichedPRDContext?,
        strategy: ThinkingStrategy,
        onChunk: @escaping (String) async throws -> Void
    ) async throws -> (content: String, prompt: String) {
        let sectionContext = await contextExtractor.extractContext(
            for: sectionType,
            from: request
        )

        let prompt = await promptBuilder.buildSectionPrompt(
            for: sectionType,
            sectionContext: sectionContext,
            enrichedContext: enrichedContext,
            contextBuilder: contextBuilder
        )

        let content = try await contentGenerator.generateContent(
            prompt: prompt,
            prdId: prdId,
            sectionId: sectionId,
            sectionType: sectionType,
            strategy: strategy,
            onChunk: onChunk
        )

        return (content, prompt)
    }

    private func selectStrategyForSection(
        prdId: UUID,
        sectionType: SectionType,
        request: PRDRequest,
        hasCodebase: Bool
    ) async throws -> ThinkingStrategy {
        // Ask LLM to recommend strategy based on section requirements
        return try await strategyRecommender.recommendStrategy(
            prdId: prdId,
            sectionType: sectionType,
            projectTitle: request.title,
            projectDescription: request.description,
            requirementCount: request.requirements.count,
            hasCodebase: hasCodebase,
            hasMockups: request.mockupFileIds?.isEmpty == false
        )
    }

    private func trackStrategyDecision(
        prdId: UUID, sectionId: UUID, strategy: ThinkingStrategy, sectionType: SectionType
    ) async throws {
        guard let tracker = intelligenceTracker else { return }
        let decision = try await tracker.trackStrategyDecision(
            prdId: prdId, sectionId: sectionId,
            strategyChosen: ThinkingStrategyStringConverter.toString(strategy),
            reasoning: "LLM-recommended for \(sectionType.displayName)",
            confidenceScore: nil, inputCharacteristics: InputCharacteristics(), alternativesConsidered: []
        )
        print("📊 [Intelligence] Tracked: \(decision.id) → \(sectionType.displayName)")
    }
}

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
    private let strategySelector: SectionStrategySelector
    private let sectionVerification: SectionVerification
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
        intelligenceTracker: IntelligenceTrackerService? = nil,
        verificationService: ChainOfVerificationService? = nil,
        llmVerifier: LLMResponseVerifier? = nil
    ) {
        self.aiProvider = aiProvider
        self.promptBuilder = promptBuilder
        self.contextExtractor = contextExtractor
        self.contextBuilder = contextBuilder
        self.clarificationService = clarificationService
        self.interactionHandler = interactionHandler
        self.thinkingOrchestrator = thinkingOrchestrator
        self.sectionVerification = SectionVerification(verificationService: verificationService)

        // Use provided verifier (DRY - created once in factory with 80% threshold)
        let verifier = llmVerifier ?? LLMResponseVerifier(
            verificationService: verificationService,
            intelligenceTracker: intelligenceTracker,
            verificationThreshold: 0.8
        )

        self.strategySelector = SectionStrategySelector(
            aiProvider: aiProvider,
            intelligenceTracker: intelligenceTracker,
            verifier: verifier
        )
        self.llmTracker = SectionLLMTracker(
            intelligenceTracker: intelligenceTracker,
            aiProvider: aiProvider
        )

        self.contentGenerator = SectionContentGenerator(
            aiProvider: aiProvider,
            thinkingOrchestrator: thinkingOrchestrator,
            llmTracker: llmTracker,
            verifier: verifier
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

        return try await generateAndVerifySectionContent(
            sectionId: sectionId,
            sectionType: sectionType,
            order: order,
            request: request,
            prdId: prdId,
            enrichedContext: enrichedContext,
            startTime: startTime,
            onChunk: onChunk
        )
    }

    private func generateAndVerifySectionContent(
        sectionId: UUID,
        sectionType: SectionType,
        order: Int,
        request: PRDRequest,
        prdId: UUID,
        enrichedContext: EnrichedPRDContext?,
        startTime: Date,
        onChunk: @escaping (String) async throws -> Void
    ) async throws -> (section: PRDSection, strategy: ThinkingStrategy, trackingMetadata: SectionTrackingMetadata) {
        let strategy = try await strategySelector.selectAndTrackStrategy(
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

        let verifiedContent = try await sectionVerification.verifySection(
            content: content,
            sectionType: sectionType,
            request: request
        )

        let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)

        return finalizeSection(
            sectionId: sectionId,
            prdId: prdId,
            sectionType: sectionType,
            content: verifiedContent,
            originalContent: content,
            prompt: prompt,
            order: order,
            strategy: strategy,
            latencyMs: latencyMs
        )
    }

    private func finalizeSection(
        sectionId: UUID,
        prdId: UUID,
        sectionType: SectionType,
        content: String,
        originalContent: String,
        prompt: String,
        order: Int,
        strategy: ThinkingStrategy,
        latencyMs: Int
    ) -> (section: PRDSection, strategy: ThinkingStrategy, trackingMetadata: SectionTrackingMetadata) {
        let section = PRDSection(
            id: sectionId,
            type: sectionType,
            title: sectionType.displayName,
            content: content,
            order: order,
            thinkingStrategy: ThinkingStrategyStringConverter.toString(strategy)
        )

        let trackingMetadata = SectionTrackingMetadata(
            sectionId: sectionId,
            prdId: prdId,
            sectionType: sectionType,
            strategy: strategy,
            prompt: prompt,
            content: originalContent,
            latencyMs: latencyMs
        )

        return (section, strategy, trackingMetadata)
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
}

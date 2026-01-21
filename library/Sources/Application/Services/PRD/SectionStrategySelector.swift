import Foundation
import Domain

/// Handles strategy selection and tracking for PRD sections
/// Following Single Responsibility: Only selects and tracks strategies
struct SectionStrategySelector: Sendable {
    private let strategyRecommender: StrategyRecommendationService
    private let intelligenceTracker: IntelligenceTrackerService?

    init(
        aiProvider: AIProviderPort,
        intelligenceTracker: IntelligenceTrackerService?
    ) {
        self.strategyRecommender = StrategyRecommendationService(
            aiProvider: aiProvider,
            intelligenceTracker: intelligenceTracker
        )
        self.intelligenceTracker = intelligenceTracker
    }

    func selectAndTrackStrategy(
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

        try await trackStrategyDecision(
            prdId: prdId,
            sectionId: sectionId,
            strategy: strategy,
            sectionType: sectionType
        )

        return strategy
    }

    private func selectStrategyForSection(
        prdId: UUID,
        sectionType: SectionType,
        request: PRDRequest,
        hasCodebase: Bool
    ) async throws -> ThinkingStrategy {
        try await strategyRecommender.recommendStrategy(
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
        prdId: UUID,
        sectionId: UUID,
        strategy: ThinkingStrategy,
        sectionType: SectionType
    ) async throws {
        guard let tracker = intelligenceTracker else { return }
        let decision = try await tracker.trackStrategyDecision(
            prdId: prdId,
            sectionId: sectionId,
            strategyChosen: ThinkingStrategyStringConverter.toString(strategy),
            reasoning: "LLM-recommended for \(sectionType.displayName)",
            confidenceScore: nil,
            inputCharacteristics: InputCharacteristics(),
            alternativesConsidered: []
        )
        print("📊 [Intelligence] Tracked: \(decision.id) → \(sectionType.displayName)")
    }
}

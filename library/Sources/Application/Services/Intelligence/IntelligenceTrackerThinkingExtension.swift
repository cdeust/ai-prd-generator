import Foundation
import Domain

/// Extension for thinking/reasoning tracking (Strategy decisions, Thinking chain steps)
/// All prdId fields nullable - thinking happens BEFORE PRD exists
extension IntelligenceTrackerService {

    // MARK: - Strategy Decision Tracking

    /// Track a strategy decision (prdId nullable, updated via upsert when PRD created)
    public func trackStrategyDecision(
        prdId: UUID? = nil,
        sectionId: UUID? = nil,
        strategyChosen: String,
        reasoning: String,
        confidenceScore: Double?,
        inputCharacteristics: InputCharacteristics,
        alternativesConsidered: [String]
    ) async throws -> ThinkingStrategyDecision {
        let decision = ThinkingStrategyDecision(
            prdId: prdId,
            sectionId: sectionId,
            strategyChosen: strategyChosen,
            reasoning: reasoning,
            confidenceScore: confidenceScore,
            inputCharacteristics: inputCharacteristics,
            alternativesConsidered: alternativesConsidered
        )

        try await strategyTracker.recordDecision(decision)
        return decision
    }

    /// Update prdId for strategy decisions when PRD is created
    public func updateStrategyDecisionPrdId(sectionId: UUID, prdId: UUID) async throws {
        try await strategyTracker.updatePrdId(sectionId: sectionId, prdId: prdId)
    }

    // MARK: - Thinking Chain Step Tracking

    /// Track a thinking chain step (prdId nullable, updated via upsert when PRD created)
    public func trackThinkingChainStep(
        prdId: UUID? = nil,
        sectionId: UUID? = nil,
        llmInteractionId: UUID? = nil,
        stepNumber: Int,
        thoughtType: ThoughtStepType,
        content: String,
        evidenceUsed: [EvidenceReference] = [],
        confidence: Double? = nil,
        tokensUsed: Int? = nil,
        executionTimeMs: Int? = nil
    ) async throws -> ThinkingChainStep {
        let step = ThinkingChainStep(
            prdId: prdId,
            sectionId: sectionId,
            llmInteractionId: llmInteractionId,
            stepNumber: stepNumber,
            thoughtType: thoughtType,
            content: content,
            evidenceUsed: evidenceUsed,
            confidence: confidence,
            tokensUsed: tokensUsed,
            executionTimeMs: executionTimeMs
        )

        try await thinkingChainTracker.recordStep(step)
        return step
    }

    /// Track multiple thinking chain steps at once
    public func trackThinkingChainSteps(_ steps: [ThinkingChainStep]) async throws {
        try await thinkingChainTracker.recordSteps(steps)
    }

    /// Update prdId for thinking chain steps when PRD is created
    public func updateThinkingChainPrdId(sectionId: UUID, prdId: UUID) async throws {
        try await thinkingChainTracker.updatePrdId(sectionId: sectionId, prdId: prdId)
    }
}

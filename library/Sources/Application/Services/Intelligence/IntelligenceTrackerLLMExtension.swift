import Foundation
import Domain

/// Extension for LLM interaction tracking
/// prdId is nullable - all LLM calls happen during analysis BEFORE PRD exists
extension IntelligenceTrackerService {

    /// Track an LLM interaction (prdId nullable, updated via upsert when PRD created)
    public func trackLLMInteraction(
        prdId: UUID? = nil,
        sectionId: UUID? = nil,
        purpose: InteractionPurpose,
        contextType: ContextType? = nil,
        promptTemplate: String,
        actualPrompt: String,
        systemInstructions: String? = nil,
        llmModel: String,
        provider: String,
        parameters: LLMParameters = LLMParameters(),
        response: String,
        tokensPrompt: Int? = nil,
        tokensResponse: Int? = nil,
        latencyMs: Int? = nil,
        thinkingStrategy: String? = nil,
        thinkingDepth: Int? = nil
    ) async throws -> LLMInteractionTrace {
        let tokensTotal = costCalculator.calculateTotal(prompt: tokensPrompt, response: tokensResponse)
        let costUsd = costCalculator.calculateCost(model: llmModel, tokens: tokensTotal)

        updateTokenMetrics(tokens: tokensTotal, cost: costUsd)

        let trace = LLMInteractionTrace(
            prdId: prdId,
            sectionId: sectionId,
            purpose: purpose,
            contextType: contextType,
            promptTemplate: promptTemplate,
            actualPrompt: actualPrompt,
            systemInstructions: systemInstructions,
            llmModel: llmModel,
            provider: provider,
            parameters: parameters,
            response: response,
            tokensPrompt: tokensPrompt,
            tokensResponse: tokensResponse,
            tokensTotal: tokensTotal,
            latencyMs: latencyMs,
            costUsd: costUsd,
            thinkingStrategy: thinkingStrategy,
            thinkingDepth: thinkingDepth
        )

        try await llmTracker.recordInteraction(trace)
        return trace
    }

    /// Update prdId for LLM interactions when PRD is created
    public func updateLLMInteractionPrdId(sectionId: UUID, prdId: UUID) async throws {
        try await llmTracker.updatePrdId(sectionId: sectionId, prdId: prdId)
    }

    /// Update prdId for Phase 1 LLM interactions (requirement analysis without section_id)
    public func updatePhase1LLMInteractionPrdId(prdId: UUID) async throws {
        try await llmTracker.updatePhase1PrdId(prdId: prdId)
    }
}

import Foundation
import Domain

/// Handles LLM interaction tracking for PRD section generation
/// Single Responsibility: Track LLM calls made during section generation
struct SectionLLMTracker: Sendable {
    private let intelligenceTracker: IntelligenceTrackerService?
    private let aiProvider: AIProviderPort

    init(intelligenceTracker: IntelligenceTrackerService?, aiProvider: AIProviderPort) {
        self.intelligenceTracker = intelligenceTracker
        self.aiProvider = aiProvider
    }

    /// Track LLM interaction for orchestrator-based section generation
    func trackOrchestratorGeneration(
        prdId: UUID,
        sectionId: UUID,
        sectionType: SectionType,
        prompt: String,
        content: String,
        strategy: ThinkingStrategy,
        latencyMs: Int
    ) async {
        guard let tracker = intelligenceTracker else {
            print("⚠️ [Intelligence] No tracker - skipping section generation tracking")
            return
        }
        do {
            _ = try await tracker.trackLLMInteraction(
                prdId: prdId,
                sectionId: sectionId,
                purpose: .sectionGeneration,
                contextType: .initial,
                promptTemplate: "section_\(sectionType.rawValue)",
                actualPrompt: prompt,
                systemInstructions: nil,
                llmModel: aiProvider.modelName,
                provider: aiProvider.providerName,
                parameters: LLMParameters(temperature: 0.7),
                response: content,
                tokensPrompt: nil,
                tokensResponse: nil,
                latencyMs: latencyMs,
                thinkingStrategy: ThinkingStrategyStringConverter.toString(strategy),
                thinkingDepth: nil
            )
            print("✅ [Intelligence] Tracked section generation for \(sectionType.displayName) (PRD: \(prdId), Section: \(sectionId))")
        } catch {
            print("❌ [Intelligence] Failed to track section generation: \(error)")
        }
    }

    /// Track LLM interaction for fallback direct AI calls
    func trackFallbackGeneration(
        prdId: UUID,
        sectionId: UUID,
        sectionType: SectionType,
        prompt: String,
        content: String,
        latencyMs: Int
    ) async {
        guard let tracker = intelligenceTracker else {
            print("⚠️ [Intelligence] No tracker - skipping fallback generation tracking")
            return
        }
        do {
            _ = try await tracker.trackLLMInteraction(
                prdId: prdId,
                sectionId: sectionId,
                purpose: .sectionGeneration,
                contextType: .initial,
                promptTemplate: "section_\(sectionType.rawValue)_fallback",
                actualPrompt: prompt,
                systemInstructions: nil,
                llmModel: aiProvider.modelName,
                provider: aiProvider.providerName,
                parameters: LLMParameters(temperature: 0.7),
                response: content,
                tokensPrompt: nil,
                tokensResponse: nil,
                latencyMs: latencyMs,
                thinkingStrategy: nil,
                thinkingDepth: nil
            )
            print("✅ [Intelligence] Tracked fallback section generation for \(sectionType.displayName) (PRD: \(prdId), Section: \(sectionId))")
        } catch {
            print("❌ [Intelligence] Failed to track fallback generation: \(error)")
        }
    }

    /// Track clarification answer
    func trackClarification(
        prdId: UUID,
        question: ClarificationQuestion<String, Int, String>,
        answer: String,
        sectionType: SectionType
    ) async {
        guard let tracker = intelligenceTracker else { return }
        do {
            _ = try await tracker.trackClarification(
                prdId: prdId,
                questionId: question.id,
                questionText: question.question,
                reasoningForAsking: question.rationale,
                gapAddressed: sectionType.displayName,
                userAnswer: answer,
                answerTimestamp: Date()
            )
            print("✅ [Intelligence] Tracked clarification for \(sectionType.displayName) (PRD: \(prdId))")
        } catch {
            print("❌ [Intelligence] Failed to track clarification: \(error)")
        }
    }
}

import Foundation
import Domain

/// Handles content generation for PRD sections using different strategies
/// Single Responsibility: Generate section content with orchestrator or fallback
struct SectionContentGenerator: Sendable {
    private let aiProvider: AIProviderPort
    private let thinkingOrchestrator: ThinkingOrchestratorUseCase?
    private let llmTracker: SectionLLMTracker
    private let verifier: LLMResponseVerifier?

    init(
        aiProvider: AIProviderPort,
        thinkingOrchestrator: ThinkingOrchestratorUseCase?,
        llmTracker: SectionLLMTracker,
        verifier: LLMResponseVerifier? = nil
    ) {
        self.aiProvider = aiProvider
        self.thinkingOrchestrator = thinkingOrchestrator
        self.llmTracker = llmTracker
        self.verifier = verifier
    }

    func generateContent(
        prompt: String,
        prdId: UUID,
        sectionId: UUID,
        sectionType: SectionType,
        strategy: ThinkingStrategy,
        onChunk: @escaping (String) async throws -> Void
    ) async throws -> String {
        let startTime = Date()

        if let orchestrator = thinkingOrchestrator {
            return try await generateWithOrchestrator(
                orchestrator: orchestrator,
                prompt: prompt,
                prdId: prdId,
                sectionId: sectionId,
                sectionType: sectionType,
                strategy: strategy,
                startTime: startTime,
                onChunk: onChunk
            )
        }

        return try await generateWithFallback(
            prompt: prompt,
            prdId: prdId,
            sectionId: sectionId,
            sectionType: sectionType,
            startTime: startTime,
            onChunk: onChunk
        )
    }

    private func generateWithOrchestrator(
        orchestrator: ThinkingOrchestratorUseCase,
        prompt: String,
        prdId: UUID,
        sectionId: UUID,
        sectionType: SectionType,
        strategy: ThinkingStrategy,
        startTime: Date,
        onChunk: @escaping (String) async throws -> Void
    ) async throws -> String {
        let result = try await orchestrator.execute(problem: prompt, preferredStrategy: strategy)
        let content = result.conclusion
        let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)

        // Apply Chain of Verification to orchestrator response
        if let verifier = verifier {
            let context = "PRD section generation (\(sectionType)) with thinking orchestrator"
            let verificationResult = try await verifier.verifyResponse(
                prompt: prompt,
                response: content,
                context: context,
                verificationType: .prdQuality
            )

            if !verificationResult.verified {
                print("⚠️ [SectionContentGenerator] Orchestrator verification failed - using response with caution")
            }
        }

        await llmTracker.trackOrchestratorGeneration(
            prdId: prdId,
            sectionId: sectionId,
            sectionType: sectionType,
            prompt: prompt,
            content: content,
            strategy: strategy,
            latencyMs: latencyMs
        )

        try await onChunk(content)
        return content
    }

    private func generateWithFallback(
        prompt: String,
        prdId: UUID,
        sectionId: UUID,
        sectionType: SectionType,
        startTime: Date,
        onChunk: @escaping (String) async throws -> Void
    ) async throws -> String {
        print("⚠️ No orchestrator - using direct AI call (strategy won't be applied)")
        var fullContent = ""
        for try await chunk in try await aiProvider.streamText(prompt: prompt, temperature: 0.7) {
            fullContent += chunk
            try await onChunk(chunk)
        }

        // Apply Chain of Verification to fallback response
        if let verifier = verifier {
            let context = "PRD section generation (\(sectionType)) with fallback (no orchestrator)"
            let verificationResult = try await verifier.verifyResponse(
                prompt: prompt,
                response: fullContent,
                context: context,
                verificationType: .prdQuality
            )

            if !verificationResult.verified {
                print("⚠️ [SectionContentGenerator] Fallback verification failed - using response with caution")
            }
        }

        let latencyMs = Int(Date().timeIntervalSince(startTime) * 1000)
        await llmTracker.trackFallbackGeneration(
            prdId: prdId,
            sectionId: sectionId,
            sectionType: sectionType,
            prompt: prompt,
            content: fullContent,
            latencyMs: latencyMs
        )

        return fullContent
    }
}

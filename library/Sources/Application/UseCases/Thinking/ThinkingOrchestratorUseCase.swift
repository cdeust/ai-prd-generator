import Foundation
import Domain

/// Orchestrator for selecting optimal thinking pattern based on problem characteristics
/// Single Responsibility: Routes problems to appropriate thinking strategy
public struct ThinkingOrchestratorUseCase: Sendable {
    private let strategySelector: ThinkingStrategySelector
    private let strategyExecutor: ThinkingStrategyExecutor

    public init(
        aiProvider: AIProviderPort,
        codebaseRepository: CodebaseRepositoryPort? = nil,
        embeddingGenerator: EmbeddingGeneratorPort? = nil,
        intelligenceTracker: IntelligenceTrackerService? = nil
    ) {
        self.strategySelector = ThinkingStrategySelector()
        self.strategyExecutor = ThinkingStrategyExecutor(
            aiProvider: aiProvider,
            codebaseRepository: codebaseRepository,
            embeddingGenerator: embeddingGenerator,
            intelligenceTracker: intelligenceTracker
        )
    }

    /// Execute optimal thinking pattern based on problem analysis
    public func execute(
        problem: String,
        context: String = "",
        constraints: [String] = [],
        codebaseId: UUID? = nil,
        preferredStrategy: ThinkingStrategy? = nil,
        prdId: UUID? = nil,
        sectionId: UUID? = nil
    ) async throws -> ThinkingResult {
        let strategy = preferredStrategy ?? strategySelector.selectStrategy(
            problem: problem,
            context: context,
            hasCodebase: codebaseId != nil
        )

        let result = try await strategyExecutor.execute(
            strategy: strategy,
            problem: problem,
            context: context,
            constraints: constraints,
            codebaseId: codebaseId,
            prdId: prdId,
            sectionId: sectionId
        )

        return ThinkingResult(
            problem: problem,
            strategyUsed: strategy,
            conclusion: result.conclusion,
            confidence: result.confidence,
            metadata: result.metadata,
            timestamp: Date()
        )
    }
}

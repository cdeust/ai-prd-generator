import Foundation
import Domain

/// ReAct pattern: Reasoning + Acting with interleaved thought and action
/// Single Responsibility: Orchestrates reasoning-action cycles
public struct ReActUseCase: Sendable {
    private let cycleBuilder: ReActCycleBuilder
    private let actionExecutor: ReActActionExecutor

    public init(
        aiProvider: AIProviderPort,
        codebaseRepository: CodebaseRepositoryPort? = nil,
        embeddingGenerator: EmbeddingGeneratorPort? = nil
    ) {
        self.cycleBuilder = ReActCycleBuilder(aiProvider: aiProvider)
        self.actionExecutor = ReActActionExecutor(
            aiProvider: aiProvider,
            codebaseRepository: codebaseRepository,
            embeddingGenerator: embeddingGenerator
        )
    }

    /// Execute ReAct pattern with reasoning-action cycles
    public func execute(
        task: String,
        initialContext: String = "",
        codebaseId: UUID? = nil,
        maxCycles: Int = 5
    ) async throws -> ReActResult {
        var trajectory: [ReActStep] = []
        var currentContext = initialContext

        for cycle in 0..<maxCycles {
            let (thought, action) = try await cycleBuilder.nextCycle(
                task: task,
                context: currentContext,
                trajectory: trajectory,
                cycle: cycle
            )

            let actionResult = try await actionExecutor.execute(
                action: action,
                codebaseId: codebaseId
            )

            let step = ReActStep(
                id: UUID(),
                cycle: cycle,
                thought: thought,
                action: action,
                actionResult: actionResult,
                timestamp: Date()
            )

            trajectory.append(step)
            currentContext = cycleBuilder.updateContext(
                current: currentContext,
                step: step
            )

            if cycleBuilder.shouldTerminate(
                trajectory: trajectory,
                maxCycles: maxCycles
            ) {
                break
            }
        }

        return synthesizeResult(
            task: task,
            trajectory: trajectory,
            finalContext: currentContext
        )
    }

    // MARK: - Private Methods

    private func synthesizeResult(
        task: String,
        trajectory: [ReActStep],
        finalContext: String
    ) -> ReActResult {
        let conclusion = trajectory.last?.actionResult.data ?? "No conclusion reached"

        return ReActResult(
            task: task,
            trajectory: trajectory,
            conclusion: conclusion,
            totalCycles: trajectory.count,
            finalContext: finalContext
        )
    }
}

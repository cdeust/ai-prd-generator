import Foundation
import Domain
/// Executes specific thinking strategies
/// Single Responsibility: Route to and execute specific strategy implementations
public struct ThinkingStrategyExecutor: Sendable {
    private let aiProvider: AIProviderPort
    private let codebaseRepository: CodebaseRepositoryPort?
    private let embeddingGenerator: EmbeddingGeneratorPort?
    private let promptingExecutor: PromptingStrategyExecutor
    private let intelligenceTracker: IntelligenceTrackerService?
    public init(
        aiProvider: AIProviderPort,
        codebaseRepository: CodebaseRepositoryPort? = nil,
        embeddingGenerator: EmbeddingGeneratorPort? = nil,
        intelligenceTracker: IntelligenceTrackerService? = nil
    ) {
        self.aiProvider = aiProvider
        self.codebaseRepository = codebaseRepository
        self.embeddingGenerator = embeddingGenerator
        self.promptingExecutor = PromptingStrategyExecutor(aiProvider: aiProvider)
        self.intelligenceTracker = intelligenceTracker
    }
    public func execute(
        strategy: ThinkingStrategy,
        problem: String,
        context: String,
        constraints: [String],
        codebaseId: UUID?,
        prdId: UUID? = nil,
        sectionId: UUID? = nil
    ) async throws -> StrategyResult {
        switch strategy {
        case .chainOfThought:
            return try await executeCoT(problem, context, constraints, prdId, sectionId)
        case .treeOfThoughts:
            return try await executeToT(problem, context)
        case .graphOfThoughts:
            return try await executeGoT(problem, context)
        case .react:
            return try await executeReAct(problem, context, codebaseId, prdId, sectionId)
        case .reflexion:
            return try await executeReflexion(problem, context, constraints)
        case .planAndSolve:
            return try await executePlanSolve(problem, context, constraints, prdId, sectionId)
        case .verifiedReasoning:
            return try await executeVerified(problem, context, constraints, codebaseId)
        case .recursiveRefinement:
            return try await executeTRM(problem, context, constraints)
        case .zeroShot, .fewShot, .selfConsistency, .generateKnowledge, .promptChaining, .multimodalCoT, .metaPrompting:
            return try await executePromptingStrategy(strategy, problem, context, constraints)
        case .enhanced(let baseStrategy, let enhancement):
            return try await executeEnhanced(
                baseStrategy: baseStrategy,
                enhancement: enhancement,
                problem: problem,
                context: context,
                constraints: constraints,
                codebaseId: codebaseId
            )
        }
    }
    private func executePromptingStrategy(
        _ strategy: ThinkingStrategy,
        _ problem: String,
        _ context: String,
        _ constraints: [String]
    ) async throws -> StrategyResult {
        switch strategy {
        case .zeroShot:
            return try await promptingExecutor.executeZeroShot(problem, context)
        case .fewShot(let examples):
            return try await promptingExecutor.executeFewShot(problem, context, examples: examples)
        case .selfConsistency:
            return try await promptingExecutor.executeSelfConsistency(problem, context)
        case .generateKnowledge:
            return try await promptingExecutor.executeGenerateKnowledge(problem, context)
        case .promptChaining:
            return try await promptingExecutor.executePromptChaining(problem, context, constraints)
        case .multimodalCoT:
            return try await promptingExecutor.executeMultimodalCoT(problem, context)
        case .metaPrompting:
            return try await promptingExecutor.executeMetaPrompting(problem, context)
        default:
            fatalError("Unexpected strategy")
        }
    }
    private func executeCoT(
        _ problem: String,
        _ context: String,
        _ constraints: [String],
        _ prdId: UUID?,
        _ sectionId: UUID?
    ) async throws -> StrategyResult {
        let useCase = AnalyzeProblemUseCase(aiProvider: aiProvider)
        let result = try await useCase.execute(problem: problem, context: context, constraints: constraints)
        if let tracker = intelligenceTracker {
            let steps = result.thoughts.map { thought in
                ThinkingChainStep(
                    prdId: prdId, sectionId: sectionId, stepNumber: thought.step,
                    thoughtType: .reasoning, content: thought.content, evidenceUsed: [],
                    confidence: thought.confidence, tokensUsed: nil, executionTimeMs: nil
                )
            }
            try? await tracker.trackThinkingChainSteps(steps)
        }
        return StrategyResult(
            conclusion: result.conclusion,
            confidence: result.confidence,
            metadata: ["thoughts_count": String(result.thoughts.count)]
        )
    }
    private func executeToT(_ problem: String, _ context: String) async throws -> StrategyResult {
        let useCase = TreeOfThoughtsUseCase(aiProvider: aiProvider)
        let result = try await useCase.execute(problem: problem, context: context)
        return StrategyResult(
            conclusion: "Best path: \(result.bestPath.joined(separator: " → "))",
            confidence: result.bestScore,
            metadata: ["nodes_explored": String(result.totalNodesExplored)]
        )
    }
    private func executeGoT(_ problem: String, _ context: String) async throws -> StrategyResult {
        let useCase = GraphOfThoughtsUseCase(aiProvider: aiProvider)
        let result = try await useCase.execute(problem: problem, context: context)
        return StrategyResult(
            conclusion: result.synthesis ?? "Graph incomplete",
            confidence: 0.8,
            metadata: ["nodes": String(result.nodes.count)]
        )
    }
    private func executeReAct(
        _ problem: String,
        _ context: String,
        _ codebaseId: UUID?,
        _ prdId: UUID?,
        _ sectionId: UUID?
    ) async throws -> StrategyResult {
        let useCase = ReActUseCase(
            aiProvider: aiProvider,
            codebaseRepository: codebaseRepository,
            embeddingGenerator: embeddingGenerator
        )
        let result = try await useCase.execute(task: problem, initialContext: context, codebaseId: codebaseId)
        if let tracker = intelligenceTracker {
            var steps: [ThinkingChainStep] = []
            for (index, reactStep) in result.trajectory.enumerated() {
                steps.append(ThinkingChainStep(
                    prdId: prdId,
                    sectionId: sectionId,
                    stepNumber: index * 2 + 1,
                    thoughtType: .observation,
                    content: reactStep.thought.content,
                    evidenceUsed: [],
                    confidence: reactStep.thought.confidence,
                    tokensUsed: nil,
                    executionTimeMs: nil
                ))
                steps.append(ThinkingChainStep(
                    prdId: prdId,
                    sectionId: sectionId,
                    stepNumber: index * 2 + 2,
                    thoughtType: .action,
                    content: "Action: \(reactStep.action.actionType) -> \(reactStep.actionResult.success ? "Success" : "Failed")",
                    evidenceUsed: [],
                    confidence: nil,
                    tokensUsed: nil,
                    executionTimeMs: nil
                ))
            }
            try? await tracker.trackThinkingChainSteps(steps)
        }
        return StrategyResult(
            conclusion: result.conclusion,
            confidence: 0.85,
            metadata: ["cycles": String(result.totalCycles)]
        )
    }
    private func executeReflexion(
        _ problem: String,
        _ context: String,
        _ constraints: [String]
    ) async throws -> StrategyResult {
        let useCase = ReflexionUseCase(aiProvider: aiProvider)
        let result = try await useCase.execute(problem: problem, context: context, constraints: constraints)
        return StrategyResult(
            conclusion: result.finalConclusion,
            confidence: result.finalQualityScore,
            metadata: ["iterations": String(result.iterationsUsed)]
        )
    }
    private func executePlanSolve(
        _ problem: String,
        _ context: String,
        _ constraints: [String],
        _ prdId: UUID?,
        _ sectionId: UUID?
    ) async throws -> StrategyResult {
        let useCase = PlanAndSolveUseCase(aiProvider: aiProvider)
        let result = try await useCase.execute(problem: problem, context: context, constraints: constraints)
        if let tracker = intelligenceTracker {
            let steps = result.executionResults.enumerated().map { (index, stepResult) in
                ThinkingChainStep(
                    prdId: prdId,
                    sectionId: sectionId,
                    stepNumber: index + 1,
                    thoughtType: .reasoning,
                    content: stepResult.output,
                    evidenceUsed: [],
                    confidence: stepResult.confidence,
                    tokensUsed: nil,
                    executionTimeMs: nil
                )
            }
            try? await tracker.trackThinkingChainSteps(steps)
        }
        return StrategyResult(
            conclusion: result.finalOutput,
            confidence: result.averageConfidence,
            metadata: ["steps": String(result.plan.steps.count)]
        )
    }
    private func executeVerified(
        _ problem: String,
        _ context: String,
        _ constraints: [String],
        _ codebaseId: UUID?
    ) async throws -> StrategyResult {
        let useCase = ExecuteVerifiedReasoningUseCase(
            aiProvider: aiProvider,
            codebaseRepository: codebaseRepository,
            embeddingGenerator: embeddingGenerator
        )
        let result = try await useCase.execute(
            problem: problem,
            initialContext: context,
            constraints: constraints,
            codebaseId: codebaseId
        )
        return StrategyResult(
            conclusion: result.conclusion,
            confidence: result.confidence,
            metadata: ["reliability": String(format: "%.2f", result.reliabilityScore)]
        )
    }
    private func executeTRM(
        _ problem: String,
        _ context: String,
        _ constraints: [String]
    ) async throws -> StrategyResult {
        let useCase = TRMReasoningUseCase(aiProvider: aiProvider)
        let result = try await useCase.execute(
            problem: problem,
            context: context,
            constraints: constraints
        )
        return StrategyResult(
            conclusion: result.finalPrediction,
            confidence: result.finalConfidence,
            metadata: [
                "iterations": String(result.totalIterations),
                "halted_early": String(result.haltedEarly),
                "converged": String(result.converged())
            ]
        )
    }
    private func executeEnhanced(
        baseStrategy: BaseStrategy,
        enhancement: EnhancementType,
        problem: String,
        context: String,
        constraints: [String],
        codebaseId: UUID?
    ) async throws -> StrategyResult {
        switch baseStrategy {
        case .verifiedReasoning:
            let useCase = ExecuteVerifiedReasoningUseCase(
                aiProvider: aiProvider,
                codebaseRepository: codebaseRepository,
                embeddingGenerator: embeddingGenerator
            )
            let result = try await useCase.execute(
                problem: problem,
                initialContext: context,
                constraints: constraints,
                codebaseId: codebaseId,
                reliabilityTarget: 0.95
            )
            return StrategyResult(
                conclusion: result.conclusion,
                confidence: result.confidence,
                metadata: [
                    "reliability": String(format: "%.2f", result.reliabilityScore),
                    "iterations": String(result.iterationsNeeded),
                    "enhanced": "true"
                ]
            )
        default:
            throw ExecutionError.enhancementNotSupported(baseStrategy)
        }
    }
}

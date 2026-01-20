import Foundation
import Domain

/// Executes prompting-based strategies
/// Separated from reasoning strategies for single responsibility
struct PromptingStrategyExecutor: Sendable {
    private let aiProvider: AIProviderPort

    init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    func executeZeroShot(_ problem: String, _ context: String) async throws -> StrategyResult {
        let useCase = ZeroShotUseCase(aiProvider: aiProvider)
        let result = try await useCase.execute(
            problem: problem,
            context: context,
            taskInstructions: "Solve this problem directly."
        )
        return StrategyResult(conclusion: result.solution, confidence: result.confidence, metadata: [:])
    }

    func executeFewShot(_ problem: String, _ context: String, examples: [Example]) async throws -> StrategyResult {
        let useCase = FewShotUseCase(aiProvider: aiProvider)
        let result = try await useCase.execute(
            problem: problem,
            context: context,
            examples: examples,
            taskInstructions: "Follow the pattern shown."
        )
        return StrategyResult(conclusion: result.solution, confidence: result.confidence, metadata: [:])
    }

    func executeSelfConsistency(_ problem: String, _ context: String) async throws -> StrategyResult {
        let useCase = SelfConsistencyUseCase(aiProvider: aiProvider, sampleCount: 5)
        let result = try await useCase.execute(
            problem: problem,
            context: context,
            taskInstructions: "Reason carefully."
        )
        return StrategyResult(conclusion: result.solution, confidence: result.confidence, metadata: [:])
    }

    func executeGenerateKnowledge(_ problem: String, _ context: String) async throws -> StrategyResult {
        let useCase = GenerateKnowledgeUseCase(aiProvider: aiProvider)
        let result = try await useCase.execute(
            problem: problem,
            context: context,
            domain: "software engineering"
        )
        return StrategyResult(conclusion: result.solution, confidence: result.confidence, metadata: [:])
    }

    func executePromptChaining(_ problem: String, _ context: String, _ constraints: [String]) async throws -> StrategyResult {
        let useCase = PromptChainingUseCase(aiProvider: aiProvider)
        let chain = [
            ChainStep(name: "Analysis", instruction: "Analyze requirements", guideline: "Be thorough"),
            ChainStep(name: "Solution", instruction: "Design solution", guideline: "Be specific")
        ]
        let result = try await useCase.execute(problem: problem, context: context, chain: chain)
        return StrategyResult(conclusion: result.solution, confidence: result.confidence, metadata: [:])
    }

    func executeMultimodalCoT(_ problem: String, _ context: String) async throws -> StrategyResult {
        let useCase = MultimodalCoTUseCase(aiProvider: aiProvider, visionAnalysis: nil)
        let result = try await useCase.execute(
            problem: problem,
            context: context,
            imageUrls: [],
            constraints: []
        )
        return StrategyResult(conclusion: result.solution, confidence: result.confidence, metadata: [:])
    }

    func executeMetaPrompting(_ problem: String, _ context: String) async throws -> StrategyResult {
        let useCase = MetaPromptingUseCase(aiProvider: aiProvider)
        let meta = MetaInstructions(
            role: .productManager,
            reasoningStrategy: "Think systematically",
            perspectives: ["User needs", "Technical feasibility"],
            qualityCriteria: ["Clear", "Actionable"]
        )
        let result = try await useCase.execute(problem: problem, context: context, metaInstructions: meta)
        return StrategyResult(conclusion: result.solution, confidence: result.confidence, metadata: [:])
    }
}

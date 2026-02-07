import AIPRDMetaPromptingEngine
import AIPRDRAGEngine
import AIPRDSharedUtilities
import Application
import Foundation

/// Container for individual meta-prompting use cases
/// Use when you need fine-grained control over specific strategies
struct MetaPromptingUseCases: Sendable {
    let aiProvider: AIProviderPort
    let ragEngine: RAGEngineProtocol

    public func zeroShot() -> ZeroShotUseCase {
        ZeroShotUseCase(aiProvider: aiProvider)
    }

    public func fewShot() -> FewShotUseCase {
        FewShotUseCase(aiProvider: aiProvider)
    }

    public func selfConsistency(sampleCount: Int = 5) -> SelfConsistencyUseCase {
        SelfConsistencyUseCase(aiProvider: aiProvider, sampleCount: sampleCount)
    }

    public func chainOfThought() -> AnalyzeProblemUseCase {
        AnalyzeProblemUseCase(aiProvider: aiProvider, ragEngine: ragEngine)
    }

    public func treeOfThoughts() -> TreeOfThoughtsUseCase {
        TreeOfThoughtsUseCase(aiProvider: aiProvider)
    }

    public func graphOfThoughts() -> GraphOfThoughtsUseCase {
        GraphOfThoughtsUseCase(aiProvider: aiProvider)
    }

    public func react() -> ReActUseCase {
        ReActUseCase(aiProvider: aiProvider, ragEngine: ragEngine)
    }

    public func reflexion() -> ReflexionUseCase {
        ReflexionUseCase(aiProvider: aiProvider)
    }

    public func planAndSolve() -> PlanAndSolveUseCase {
        PlanAndSolveUseCase(aiProvider: aiProvider)
    }

    public func trmReasoning() -> TRMReasoningUseCase {
        TRMReasoningUseCase(aiProvider: aiProvider)
    }

    public func metaPrompting() -> MetaPromptingUseCase {
        MetaPromptingUseCase(aiProvider: aiProvider)
    }
}

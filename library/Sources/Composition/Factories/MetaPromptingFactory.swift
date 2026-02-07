import AIPRDMetaPromptingEngine
import AIPRDRAGEngine
import AIPRDSharedUtilities
import Application
import AIPRDSharedUtilities
import Foundation

/// Factory for creating Meta-Prompting Engine components
/// Following Single Responsibility: Handles MetaPrompting-specific dependency creation
struct MetaPromptingFactory: Sendable {
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    /// Create Meta-Prompting Engine with automatic fallback
    /// - Parameters:
    ///   - aiProvider: AI provider for reasoning
    ///   - ragEngine: RAG engine for context retrieval
    /// - Returns: Engine or degraded result
    func createMetaPromptingEngine(
        aiProvider: AIProviderPort,
        ragEngine: RAGEngineProtocol
    ) -> MetaPromptingEngineResult {
        let engine = MetaPromptingEngine(
            aiProvider: aiProvider,
            ragEngine: ragEngine
        )

        print("✅ [MetaPromptingFactory] Meta-Prompting Engine loaded")
        print("   Strategies available: 14+ (CoT, ToT, GoT, ReAct, Reflexion, TRM, etc.)")

        return .engine(engine)
    }

    /// Create use case container for direct access
    func createUseCases(
        aiProvider: AIProviderPort,
        ragEngine: RAGEngineProtocol
    ) -> MetaPromptingUseCases {
        MetaPromptingUseCases(aiProvider: aiProvider, ragEngine: ragEngine)
    }
}

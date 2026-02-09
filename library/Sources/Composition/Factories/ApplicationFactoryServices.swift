import AIPRDEncryptionEngine
import AIPRDMetaPromptingEngine
import AIPRDOrchestrationEngine
import AIPRDRAGEngine
import AIPRDSharedUtilities
import AIPRDStrategyEngine
import AIPRDVerificationEngine
import Application
import Foundation
import InfrastructureCore

/// Service accessors for ApplicationFactory
extension ApplicationFactory {

    func getRepositoryConnection() -> RepositoryConnectionPort? {
        repositoryConnection
    }

    func getMockupRepository() -> MockupRepositoryPort? {
        cachedDependencies?.mockupRepository
    }

    func getCodebaseRepository() -> CodebaseRepositoryPort? {
        codebaseRepository
    }

    /// Get RAG Engine for hybrid search and CoT retrieval
    /// Always returns a valid engine (full or degraded mode)
    func getRAGEngine() -> RAGEngineProtocol {
        guard let dependencies = cachedDependencies else {
            print("⚠️ [ApplicationFactory] No dependencies - using degraded RAG")
            return DegradedRAGService()
        }

        let ragFactory = RAGFactory(configuration: configuration)
        let result = ragFactory.createRAGEngineWithFallback(aiProvider: dependencies.aiProvider)
        return result.engine
    }

    /// Get RAG Engine with mode information
    func getRAGEngineWithMode() -> RAGServiceResult {
        guard let dependencies = cachedDependencies else {
            print("⚠️ [ApplicationFactory] No dependencies - using degraded RAG")
            return .degraded(DegradedRAGService())
        }

        let ragFactory = RAGFactory(configuration: configuration)
        return ragFactory.createRAGEngineWithFallback(aiProvider: dependencies.aiProvider)
    }

    /// Get vision analyzer for mockup analysis
    @available(iOS 15.0, macOS 12.0, *)
    func getVisionAnalyzer() -> VisionAnalysisPort? {
        aiComponentsFactory.createVisionAnalyzer()
    }

    /// Get intelligence tracker for tracking analysis
    func getIntelligenceTracker() -> IntelligenceTrackerService? {
        let intelligenceFactory = IntelligenceFactory(configuration: configuration)
        do {
            return try intelligenceFactory.createIntelligenceTracker()
        } catch {
            print("⚠️ [ApplicationFactory] IntelligenceTracker creation failed: \(error)")
            return nil
        }
    }

    /// Get GitHub integration service for repository access
    func getGitHubIntegration() -> GitHubIntegrationService {
        let authClient = GitHubCLIAuthenticator()
        return GitHubIntegrationService(
            authClient: authClient,
            apiClientFactory: { token in
                GitHubAPIClient(token: token)
            }
        )
    }

    /// Get Meta-Prompting Engine for advanced reasoning strategies
    /// Returns engine with full strategy support (CoT, ToT, GoT, ReAct, etc.)
    func getMetaPromptingEngine() -> MetaPromptingEngineProtocol? {
        guard let dependencies = cachedDependencies else {
            print("⚠️ [ApplicationFactory] No dependencies - MetaPrompting unavailable")
            return nil
        }

        let ragEngine = getRAGEngine()
        let factory = MetaPromptingFactory(configuration: configuration)
        let result = factory.createMetaPromptingEngine(
            aiProvider: dependencies.aiProvider,
            ragEngine: ragEngine
        )
        return result.engine
    }

    /// Get Meta-Prompting Engine with mode information
    func getMetaPromptingEngineWithMode() -> MetaPromptingEngineResult {
        guard let dependencies = cachedDependencies else {
            print("⚠️ [ApplicationFactory] No dependencies - MetaPrompting degraded")
            return .degraded
        }

        let ragEngine = getRAGEngine()
        let factory = MetaPromptingFactory(configuration: configuration)
        return factory.createMetaPromptingEngine(
            aiProvider: dependencies.aiProvider,
            ragEngine: ragEngine
        )
    }

    // MARK: - Strategy Engine

    /// Get Research-Weighted Strategy Engine Adapter
    /// Returns adapter for research-backed strategy selection
    func getStrategyEngineAdapter() -> StrategyEngineAdapter {
        let factory = StrategyFactory(configuration: configuration)
        let result = factory.createStrategyEngineAdapter()
        return result.adapter
    }

    /// Get Strategy Engine Adapter with mode information
    func getStrategyEngineAdapterWithMode() -> StrategyEngineResult {
        let factory = StrategyFactory(configuration: configuration)
        return factory.createStrategyEngineAdapter()
    }

    // MARK: - Encryption Engine

    /// Get Encryption Engine for PII detection and injection protection
    /// Returns engine or nil if all protections are disabled
    func getEncryptionEngine() -> EncryptionEngineProtocol? {
        let factory = EncryptionFactory(configuration: configuration)
        let aiProvider = cachedDependencies?.aiProvider
        let result = factory.createEncryptionEngine(aiProvider: aiProvider)
        switch result {
        case .engine(let engine):
            return engine
        case .degraded:
            return nil
        }
    }

    /// Get Encryption Engine with mode information
    func getEncryptionEngineWithMode() -> EncryptionEngineResult {
        let factory = EncryptionFactory(configuration: configuration)
        let aiProvider = cachedDependencies?.aiProvider
        return factory.createEncryptionEngine(aiProvider: aiProvider)
    }
}

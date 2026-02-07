import AIPRDEncryptionEngine
import AIPRDOrchestrationEngine
import AIPRDRAGEngine
import AIPRDSharedUtilities
import AIPRDStrategyEngine
import Application
import Foundation

/// Shared application services exposed to presenters
public struct SharedServices: Sendable {
    public let ragEngine: RAGEngineProtocol
    public let isRAGDegraded: Bool
    public let strategyEngine: StrategyEngineAdapter
    public let isStrategyDegraded: Bool
    public let encryptionEngine: EncryptionEngineProtocol?
    public let isEncryptionDegraded: Bool
    public let factory: UseCaseFactory?
    public let intelligenceTracker: IntelligenceTrackerService?
    public let githubIntegration: GitHubIntegrationService?

    public init(
        ragEngine: RAGEngineProtocol,
        isRAGDegraded: Bool = false,
        strategyEngine: StrategyEngineAdapter,
        isStrategyDegraded: Bool = false,
        encryptionEngine: EncryptionEngineProtocol? = nil,
        isEncryptionDegraded: Bool = false,
        factory: UseCaseFactory? = nil,
        intelligenceTracker: IntelligenceTrackerService? = nil,
        githubIntegration: GitHubIntegrationService? = nil
    ) {
        self.ragEngine = ragEngine
        self.isRAGDegraded = isRAGDegraded
        self.strategyEngine = strategyEngine
        self.isStrategyDegraded = isStrategyDegraded
        self.encryptionEngine = encryptionEngine
        self.isEncryptionDegraded = isEncryptionDegraded
        self.factory = factory
        self.intelligenceTracker = intelligenceTracker
        self.githubIntegration = githubIntegration
    }
}

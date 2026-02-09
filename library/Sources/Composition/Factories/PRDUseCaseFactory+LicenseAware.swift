import AIPRDOrchestrationEngine
import AIPRDRAGEngine
import AIPRDSharedUtilities
import AIPRDStrategyEngine
import AIPRDVerificationEngine
import Application
import Foundation

// MARK: - License-Aware Services

extension PRDUseCaseFactory {

    func createLicenseAwareThinkingService(
        aiProvider: AIProviderPort,
        ragFactory: RAGFactory
    ) -> LicenseAwareThinkingService {
        let ragResult = ragFactory.createRAGEngineWithFallback(aiProvider: aiProvider)
        let strategyFactory = StrategyFactory(configuration: configuration)
        let strategyResult = strategyFactory.createStrategyEngineAdapter()

        return LicenseAwareThinkingService(
            aiProvider: aiProvider,
            ragEngine: ragResult.engine,
            strategyEngineAdapter: strategyResult.adapter,
            licenseTier: configuration.licenseTier,
            enabledFeatures: configuration.licenseResolution.enabledFeatures
        )
    }

    func createLicenseAwareRAGService(ragEngine: RAGEngineProtocol) -> LicenseAwareRAGService {
        LicenseAwareRAGService(
            ragEngine: ragEngine,
            licenseTier: configuration.licenseTier,
            enabledFeatures: configuration.licenseResolution.enabledFeatures
        )
    }

    func createLicenseAwareVerificationService(
        aiProvider: AIProviderPort,
        unifiedEngine: UnifiedVerificationEngine?
    ) -> LicenseAwareVerificationService {
        LicenseAwareVerificationService(
            aiProvider: aiProvider,
            unifiedEngine: unifiedEngine,
            licenseTier: configuration.licenseTier,
            enabledFeatures: configuration.licenseResolution.enabledFeatures
        )
    }
}

import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import AIPRDVerificationEngine
import Application
import AIPRDSharedUtilities
import Foundation

/// Factory for creating clarification-related use cases
///
/// **License-Based Behavior:**
/// - Free tier: Basic clarification only, no verification engine
/// - Licensed tier: Full verification with UnifiedVerificationEngine
struct ClarificationUseCaseFactory: Sendable {
    private let configuration: Configuration
    private let verificationFactory: VerificationFactory

    init(configuration: Configuration) {
        self.configuration = configuration
        self.verificationFactory = VerificationFactory(configuration: configuration)
    }

    func createClarificationUseCases(
        dependencies: FactoryDependencies,
        generatePRD: GeneratePRDUseCase,
        intelligenceTracker: IntelligenceTrackerService?,
        unifiedEngine: UnifiedVerificationEngine? = nil
    ) async -> (base: ClarificationOrchestratorUseCase?, verified: VerifiedClarificationOrchestratorUseCase?) {
        let licenseTier = configuration.licenseTier

        let baseOrchestrator = createBaseOrchestrator(
            dependencies: dependencies,
            generatePRD: generatePRD,
            intelligenceTracker: intelligenceTracker,
            licenseTier: licenseTier
        )

        if licenseTier == .free {
            print("📋 [ClarificationUseCaseFactory] Free tier - basic clarification only")
            return (base: baseOrchestrator, verified: nil)
        }

        let verifiedOrchestrator = await createVerifiedOrchestrator(
            dependencies: dependencies,
            baseOrchestrator: baseOrchestrator,
            unifiedEngine: unifiedEngine,
            licenseTier: licenseTier
        )

        return (base: baseOrchestrator, verified: verifiedOrchestrator)
    }

    private func createBaseOrchestrator(
        dependencies: FactoryDependencies,
        generatePRD: GeneratePRDUseCase,
        intelligenceTracker: IntelligenceTrackerService?,
        licenseTier: LicenseTier
    ) -> ClarificationOrchestratorUseCase {
        let analyzer = RequirementAnalyzerService(
            aiProvider: dependencies.aiProvider,
            intelligenceTracker: intelligenceTracker
        )
        return ClarificationOrchestratorUseCase(
            analyzer: analyzer,
            prdGenerator: generatePRD,
            licenseTier: licenseTier
        )
    }

    private func createVerifiedOrchestrator(
        dependencies: FactoryDependencies,
        baseOrchestrator: ClarificationOrchestratorUseCase,
        unifiedEngine: UnifiedVerificationEngine?,
        licenseTier: LicenseTier
    ) async -> VerifiedClarificationOrchestratorUseCase? {
        let engine = await resolveVerificationEngine(
            aiProvider: dependencies.aiProvider,
            unifiedEngine: unifiedEngine
        )

        guard let verificationEngine = engine else {
            print("⚠️ [ClarificationUseCaseFactory] UnifiedEngine unavailable - verified orchestrator disabled")
            return nil
        }

        let historicalAnalyzer = HistoricalVerificationAnalyzer(
            evidenceRepository: dependencies.verificationEvidenceRepository
        )

        let analyzer = RequirementAnalyzerService(
            aiProvider: dependencies.aiProvider,
            intelligenceTracker: nil
        )

        print("✅ [ClarificationUseCaseFactory] VerifiedClarificationOrchestrator created (Pro tier)")

        return VerifiedClarificationOrchestratorUseCase(
            baseOrchestrator: baseOrchestrator,
            unifiedEngine: verificationEngine,
            analyzer: analyzer,
            historicalAnalyzer: historicalAnalyzer,
            evidenceRepository: dependencies.verificationEvidenceRepository,
            enableVerification: true,
            licenseTier: licenseTier
        )
    }

    private func resolveVerificationEngine(
        aiProvider: AIProviderPort,
        unifiedEngine: UnifiedVerificationEngine?
    ) async -> UnifiedVerificationEngine? {
        if let providedEngine = unifiedEngine {
            return providedEngine
        }

        let result = await verificationFactory.createUnifiedEngine(
            primaryProvider: aiProvider,
            qualityTarget: VerificationQualityTarget.adaptive
        )
        return result.unifiedEngine
    }
}

import Foundation
import Domain
import Application

/// Factory for creating clarification-related use cases
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
        intelligenceTracker: IntelligenceTrackerService?
    ) async -> (base: ClarificationOrchestratorUseCase?, verified: VerifiedClarificationOrchestratorUseCase?) {
        let analyzer = RequirementAnalyzerService(
            aiProvider: dependencies.aiProvider,
            intelligenceTracker: intelligenceTracker
        )
        let baseOrchestrator = ClarificationOrchestratorUseCase(
            analyzer: analyzer,
            prdGenerator: generatePRD
        )
        let verifiedOrchestrator: VerifiedClarificationOrchestratorUseCase?
        do {
            // Create verification service WITH evidence repository for persistence
            let verificationService = try await verificationFactory.createVerificationService(
                primaryProvider: dependencies.aiProvider,
                evidenceRepository: dependencies.verificationEvidenceRepository
            )
            // Create historical analyzer for adaptive verification
            let historicalAnalyzer = HistoricalVerificationAnalyzer(
                repository: dependencies.verificationEvidenceRepository
            )
            verifiedOrchestrator = VerifiedClarificationOrchestratorUseCase(
                baseOrchestrator: baseOrchestrator,
                verificationService: verificationService,
                analyzer: analyzer,
                historicalAnalyzer: historicalAnalyzer,
                evidenceRepository: dependencies.verificationEvidenceRepository,
                enableVerification: true
            )
        } catch {
            print("⚠️ [ClarificationUseCaseFactory] VerificationService creation failed: \(error)")
            verifiedOrchestrator = nil
        }
        return (base: baseOrchestrator, verified: verifiedOrchestrator)
    }
}

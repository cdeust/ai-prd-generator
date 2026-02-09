import AIPRDOrchestrationEngine
import AIPRDRAGEngine
import AIPRDSharedUtilities
import Application
import AIPRDSharedUtilities
import Foundation

/// Factory for creating use cases with custom dependencies
public struct UseCaseFactory: Sendable {
    private let applicationFactory: ApplicationFactory

    internal init(applicationFactory: ApplicationFactory) {
        self.applicationFactory = applicationFactory
    }

    /// Create GeneratePRDUseCase with custom interaction handler
    public func createGeneratePRDUseCase(
        interactionHandler: UserInteractionPort
    ) async -> GeneratePRDUseCase {
        return await applicationFactory.createCustomGeneratePRDUseCase(
            interactionHandler: interactionHandler
        )
    }

    /// Create vision analyzer for mockup analysis
    @available(iOS 15.0, macOS 12.0, *)
    public func createVisionAnalyzer() -> VisionAnalysisPort? {
        return applicationFactory.getVisionAnalyzer()
    }
}

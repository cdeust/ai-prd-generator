import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import AIPRDVerificationEngine
import Application
import AIPRDSharedUtilities
import Foundation

/// Extension for use case wiring helpers
extension ApplicationFactory {

    func createWiringContext(
        dependencies: FactoryDependencies
    ) async -> WiringContext {
        let promptService = aiComponentsFactory.createPromptEngineeringService()
        cachedPromptService = promptService

        let intelligenceTracker = getIntelligenceTracker()
        let unifiedEngine = await getUnifiedVerificationEngine(
            aiProvider: dependencies.aiProvider
        )
        let llmVerifier = getLLMResponseVerifier(
            unifiedEngine: unifiedEngine,
            intelligenceTracker: intelligenceTracker
        )

        return WiringContext(
            dependencies: dependencies,
            promptService: promptService,
            intelligenceTracker: intelligenceTracker,
            unifiedEngine: unifiedEngine,
            llmVerifier: llmVerifier
        )
    }

    func createCoreUseCases(
        context: WiringContext
    ) async throws -> CoreUseCases {
        let generatePRD = await useCaseBuilder.createGeneratePRDUseCase(
            dependencies: context.dependencies,
            promptService: context.promptService,
            llmVerifier: context.llmVerifier,
            unifiedEngine: context.unifiedEngine
        )

        let (listPRDs, getPRD) = useCaseBuilder.createPRDQueryUseCases(
            dependencies: context.dependencies
        )

        let sessionUseCases = useCaseBuilder.createSessionUseCases(
            dependencies: context.dependencies,
            generatePRD: generatePRD
        )

        let clarificationUseCases = await useCaseBuilder.createClarificationUseCases(
            dependencies: context.dependencies,
            generatePRD: generatePRD,
            intelligenceTracker: context.intelligenceTracker,
            unifiedEngine: context.unifiedEngine
        )

        return CoreUseCases(
            generatePRD: generatePRD,
            listPRDs: listPRDs,
            getPRD: getPRD,
            sessionUseCases: sessionUseCases,
            clarificationUseCases: clarificationUseCases
        )
    }

    func createExtendedUseCases(
        context: WiringContext
    ) async throws -> ExtendedUseCases {
        let codebaseUseCases = try useCaseBuilder.createCodebaseUseCases(
            aiProvider: context.dependencies.aiProvider
        )

        let integrationResult = try await useCaseBuilder.createIntegrationUseCases(
            codebaseRepository: codebaseUseCases.repository,
            createCodebase: codebaseUseCases.create,
            indexCodebase: codebaseUseCases.index
        )

        repositoryConnection = integrationResult.connectionRepository
        codebaseRepository = codebaseUseCases.repository

        let analyzeRequest = useCaseBuilder.createAnalyzeRequestUseCase(
            dependencies: context.dependencies,
            intelligenceTracker: context.intelligenceTracker
        )

        return ExtendedUseCases(
            codebaseUseCases: codebaseUseCases,
            integrationResult: integrationResult,
            analyzeRequest: analyzeRequest
        )
    }
}

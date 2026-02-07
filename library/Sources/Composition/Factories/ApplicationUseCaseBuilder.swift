import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import AIPRDVerificationEngine
import Foundation
import AIPRDSharedUtilities
import Application
import InfrastructureCore

/// Builder for creating application use cases
/// Handles wiring of individual use cases with their dependencies
/// Following Single Responsibility: Only builds use cases, doesn't manage factories
struct ApplicationUseCaseBuilder {
    private let configuration: Configuration
    private let prdUseCaseFactory: PRDUseCaseFactory
    private let clarificationFactory: ClarificationUseCaseFactory
    private let repositoryFactory: RepositoryFactory

    init(
        configuration: Configuration,
        prdUseCaseFactory: PRDUseCaseFactory,
        clarificationFactory: ClarificationUseCaseFactory,
        repositoryFactory: RepositoryFactory
    ) {
        self.configuration = configuration
        self.prdUseCaseFactory = prdUseCaseFactory
        self.clarificationFactory = clarificationFactory
        self.repositoryFactory = repositoryFactory
    }

    func createClarificationUseCases(
        dependencies: FactoryDependencies,
        generatePRD: GeneratePRDUseCase,
        intelligenceTracker: IntelligenceTrackerService?,
        unifiedEngine: UnifiedVerificationEngine? = nil
    ) async -> (base: ClarificationOrchestratorUseCase?, verified: VerifiedClarificationOrchestratorUseCase?) {
        await clarificationFactory.createClarificationUseCases(
            dependencies: dependencies,
            generatePRD: generatePRD,
            intelligenceTracker: intelligenceTracker,
            unifiedEngine: unifiedEngine
        )
    }

    func createAnalyzeRequestUseCase(
        dependencies: FactoryDependencies,
        intelligenceTracker: IntelligenceTrackerService?
    ) -> AnalyzeRequestUseCase {
        let contextBuilder = prdUseCaseFactory.createEnrichedContextBuilder(
            dependencies: dependencies,
            intelligenceTracker: intelligenceTracker
        )
        let requirementAnalyzer = RequirementAnalyzerService(
            aiProvider: dependencies.aiProvider,
            intelligenceTracker: intelligenceTracker
        )

        return AnalyzeRequestUseCase(
            contextBuilder: contextBuilder,
            requirementAnalyzer: requirementAnalyzer,
            intelligenceTracker: intelligenceTracker
        )
    }

    func createGeneratePRDUseCase(
        dependencies: FactoryDependencies,
        promptService: PromptEngineeringService,
        llmVerifier: LLMResponseVerifier? = nil,
        unifiedEngine: UnifiedVerificationEngine? = nil
    ) async -> GeneratePRDUseCase {
        await prdUseCaseFactory.createGeneratePRDUseCase(
            dependencies: dependencies,
            promptService: promptService,
            llmVerifier: llmVerifier,
            unifiedEngine: unifiedEngine
        )
    }

    func createIntegrationUseCases(
        codebaseRepository: CodebaseRepositoryPort?,
        createCodebase: CreateCodebaseUseCase?,
        indexCodebase: IndexCodebaseUseCase?
    ) async throws -> (
        connect: ConnectRepositoryProviderUseCase?,
        list: ListUserRepositoriesUseCase?,
        indexRemote: IndexRemoteRepositoryUseCase?,
        disconnect: DisconnectProviderUseCase?,
        listConnections: ListConnectionsUseCase?,
        connectionRepository: RepositoryConnectionPort?
    ) {
        try await IntegrationFactory(
            configuration: configuration,
            repositoryFactory: repositoryFactory
        ).createIntegrationUseCases(
            codebaseRepository: codebaseRepository,
            createCodebase: createCodebase,
            indexCodebase: indexCodebase
        )
    }

    func createPRDQueryUseCases(
        dependencies: FactoryDependencies
    ) -> (list: ListPRDsUseCase, get: GetPRDUseCase) {
        let list = ListPRDsUseCase(repository: dependencies.prdRepository)
        let get = GetPRDUseCase(repository: dependencies.prdRepository)
        return (list, get)
    }

    func createSessionUseCases(
        dependencies: FactoryDependencies,
        generatePRD: GeneratePRDUseCase
    ) -> (
        create: CreateSessionUseCase,
        continue: ContinueSessionUseCase,
        list: ListSessionsUseCase,
        get: GetSessionUseCase,
        delete: DeleteSessionUseCase
    ) {
        let create = CreateSessionUseCase(repository: dependencies.sessionRepository)
        let continueUseCase = ContinueSessionUseCase(
            sessionRepository: dependencies.sessionRepository,
            generatePRD: generatePRD
        )
        let list = ListSessionsUseCase(repository: dependencies.sessionRepository)
        let get = GetSessionUseCase(repository: dependencies.sessionRepository)
        let delete = DeleteSessionUseCase(repository: dependencies.sessionRepository)
        return (create, continueUseCase, list, get, delete)
    }

    func createCodebaseUseCases(
        aiProvider: AIProviderPort
    ) throws -> (
        create: CreateCodebaseUseCase?,
        index: IndexCodebaseUseCase?,
        list: ListCodebasesUseCase?,
        search: SearchCodebaseUseCase?,
        repository: CodebaseRepositoryPort?
    ) {
        let factory = CodebaseUseCaseFactory(configuration: configuration)
        return try factory.createUseCases(aiProvider: aiProvider)
    }
}

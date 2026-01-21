import Foundation
import Domain
import Application
import InfrastructureCore

/// Channel-agnostic factory for creating application dependencies
/// Used by CLI, REST, and WebSocket factories
public final class ApplicationFactory: @unchecked Sendable {
    private let configuration: Configuration
    private let repositoryFactory: RepositoryFactory
    private let aiComponentsFactory: AIComponentsFactory
    private let prdUseCaseFactory: PRDUseCaseFactory
    private let clarificationFactory: ClarificationUseCaseFactory
    private let useCaseBuilder: ApplicationUseCaseBuilder
    private var cachedDependencies: FactoryDependencies?
    private var cachedPromptService: PromptEngineeringService?
    private var repositoryConnection: RepositoryConnectionPort?
    private var codebaseRepository: CodebaseRepositoryPort?

    public init(configuration: Configuration = .default) {
        self.configuration = configuration
        self.repositoryFactory = RepositoryFactory(configuration: configuration)
        self.aiComponentsFactory = AIComponentsFactory(configuration: configuration)
        self.prdUseCaseFactory = PRDUseCaseFactory(
            configuration: configuration,
            aiComponentsFactory: aiComponentsFactory
        )
        self.clarificationFactory = ClarificationUseCaseFactory(configuration: configuration)
        self.useCaseBuilder = ApplicationUseCaseBuilder(
            configuration: configuration,
            prdUseCaseFactory: prdUseCaseFactory,
            clarificationFactory: clarificationFactory,
            repositoryFactory: repositoryFactory
        )
    }

    /// Create fully-configured use cases
    public func createUseCases() async throws -> ApplicationUseCases {
        let dependencies = try await createDependencies()
        self.cachedDependencies = dependencies
        return try await wireUseCases(dependencies: dependencies)
    }
    /// Create GeneratePRDUseCase with custom interaction handler
    /// Used for SSE streaming with mid-generation clarifications
    public func createCustomGeneratePRDUseCase(
        interactionHandler: UserInteractionPort
    ) async -> GeneratePRDUseCase {
        guard let dependencies = cachedDependencies else {
            fatalError("Must call createUseCases() before creating custom use cases")
        }
        let promptService = cachedPromptService ?? aiComponentsFactory.createPromptEngineeringService()
        let tokenizer = aiComponentsFactory.createTokenizer(for: configuration.aiProvider)
        let compressor = aiComponentsFactory.createCompressor(
            aiProvider: dependencies.aiProvider,
            tokenizer: tokenizer
        )
        let intelligenceTracker = getIntelligenceTracker()
        let contextBuilder = prdUseCaseFactory.createEnrichedContextBuilder(
            dependencies: dependencies, intelligenceTracker: intelligenceTracker
        )
        let contextExtractor = SectionContextExtractor()
        let requirementAnalyzer = RequirementAnalyzerService(
            aiProvider: dependencies.aiProvider,
            intelligenceTracker: intelligenceTracker
        )
        let verificationService = await getVerificationService(
            aiProvider: dependencies.aiProvider,
            evidenceRepository: dependencies.verificationEvidenceRepository
        )
        return GeneratePRDUseCase(
            aiProvider: dependencies.aiProvider,
            prdRepository: dependencies.prdRepository,
            templateRepository: dependencies.templateRepository,
            codebaseRepository: nil,
            embeddingGenerator: nil,
            mockupRepository: dependencies.mockupRepository,
            promptService: promptService,
            tokenizer: tokenizer,
            compressor: compressor,
            contextExtractor: contextExtractor,
            contextBuilder: contextBuilder,
            requirementAnalyzer: requirementAnalyzer,
            interactionHandler: interactionHandler,
            intelligenceTracker: intelligenceTracker,
            verificationService: verificationService
        )
    }
    private func createDependencies() async throws -> FactoryDependencies {
        let prdRepository = try await repositoryFactory.createPRDRepository()
        let templateRepository = try await repositoryFactory.createTemplateRepository()
        let sessionRepository = try await repositoryFactory.createSessionRepository()
        let mockupRepository = try await repositoryFactory.createMockupRepository()
        let verificationEvidenceRepository = try await repositoryFactory.createVerificationEvidenceRepository()
        let aiProvider = try await createAIProvider()

        try await repositoryFactory.seedDefaultTemplate(into: templateRepository)

        return FactoryDependencies(
            aiProvider: aiProvider,
            prdRepository: prdRepository,
            templateRepository: templateRepository,
            sessionRepository: sessionRepository,
            mockupRepository: mockupRepository,
            verificationEvidenceRepository: verificationEvidenceRepository
        )
    }
    private func createAIProvider() async throws -> AIProviderPort {
        let providerConfig = AIProviderConfiguration(
            type: configuration.aiProvider,
            apiKey: configuration.aiAPIKey,
            model: configuration.aiModel,
            region: configuration.bedrockRegion,
            accessKeyId: configuration.bedrockAccessKeyId,
            secretAccessKey: configuration.bedrockSecretAccessKey
        )

        if #available(iOS 15.0, macOS 12.0, *) {
            let factory = AIProviderFactory()
            return try await factory.createProvider(from: providerConfig)
        } else {
            return MockAIProvider()
        }
    }
    private func wireUseCases(
        dependencies: FactoryDependencies
    ) async throws -> ApplicationUseCases {
        let promptService = aiComponentsFactory.createPromptEngineeringService()
        self.cachedPromptService = promptService
        let intelligenceTracker = getIntelligenceTracker()

        let generatePRD = await useCaseBuilder.createGeneratePRDUseCase(
            dependencies: dependencies,
            promptService: promptService
        )
        let (listPRDs, getPRD) = useCaseBuilder.createPRDQueryUseCases(dependencies: dependencies)
        let sessionUseCases = useCaseBuilder.createSessionUseCases(
            dependencies: dependencies,
            generatePRD: generatePRD
        )
        let clarificationUseCases = await useCaseBuilder.createClarificationUseCases(
            dependencies: dependencies,
            generatePRD: generatePRD,
            intelligenceTracker: intelligenceTracker
        )
        let codebaseUseCases = try useCaseBuilder.createCodebaseUseCases()
        let integrationResult = try await useCaseBuilder.createIntegrationUseCases(
            codebaseRepository: codebaseUseCases.repository,
            createCodebase: codebaseUseCases.create,
            indexCodebase: codebaseUseCases.index
        )

        self.repositoryConnection = integrationResult.connectionRepository
        self.codebaseRepository = codebaseUseCases.repository
        let analyzeRequest = useCaseBuilder.createAnalyzeRequestUseCase(
            dependencies: dependencies,
            intelligenceTracker: intelligenceTracker
        )

        return assembleUseCases(
            generatePRD: generatePRD,
            listPRDs: listPRDs,
            getPRD: getPRD,
            sessionUseCases: sessionUseCases,
            clarificationUseCases: clarificationUseCases,
            analyzeRequest: analyzeRequest,
            codebaseUseCases: codebaseUseCases,
            integrationResult: integrationResult
        )
    }

    private func assembleUseCases(
        generatePRD: GeneratePRDUseCase,
        listPRDs: ListPRDsUseCase,
        getPRD: GetPRDUseCase,
        sessionUseCases: (create: CreateSessionUseCase, continue: ContinueSessionUseCase, list: ListSessionsUseCase, get: GetSessionUseCase, delete: DeleteSessionUseCase),
        clarificationUseCases: (base: ClarificationOrchestratorUseCase?, verified: VerifiedClarificationOrchestratorUseCase?),
        analyzeRequest: AnalyzeRequestUseCase,
        codebaseUseCases: (create: CreateCodebaseUseCase?, index: IndexCodebaseUseCase?, list: ListCodebasesUseCase?, search: SearchCodebaseUseCase?, repository: CodebaseRepositoryPort?),
        integrationResult: (connect: ConnectRepositoryProviderUseCase?, list: ListUserRepositoriesUseCase?, indexRemote: IndexRemoteRepositoryUseCase?, disconnect: DisconnectProviderUseCase?, listConnections: ListConnectionsUseCase?, connectionRepository: RepositoryConnectionPort?)
    ) -> ApplicationUseCases {
        ApplicationUseCases(
            generatePRD: generatePRD,
            listPRDs: listPRDs,
            getPRD: getPRD,
            createSession: sessionUseCases.create,
            continueSession: sessionUseCases.continue,
            listSessions: sessionUseCases.list,
            getSession: sessionUseCases.get,
            deleteSession: sessionUseCases.delete,
            clarificationOrchestrator: clarificationUseCases.base,
            verifiedClarificationOrchestrator: clarificationUseCases.verified,
            analyzeRequest: analyzeRequest,
            createCodebase: codebaseUseCases.create,
            indexCodebase: codebaseUseCases.index,
            listCodebases: codebaseUseCases.list,
            searchCodebase: codebaseUseCases.search,
            connectRepositoryProvider: integrationResult.connect,
            listUserRepositories: integrationResult.list,
            indexRemoteRepository: integrationResult.indexRemote,
            disconnectProvider: integrationResult.disconnect,
            listConnections: integrationResult.listConnections
        )
    }

    func getRepositoryConnection() -> RepositoryConnectionPort? {
        repositoryConnection
    }

    func getMockupRepository() -> MockupRepositoryPort? {
        cachedDependencies?.mockupRepository
    }

    func getCodebaseRepository() -> CodebaseRepositoryPort? {
        codebaseRepository
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

    /// Get verification service for Chain of Verification
    private func getVerificationService(
        aiProvider: AIProviderPort,
        evidenceRepository: VerificationEvidenceRepositoryPort?
    ) async -> ChainOfVerificationService? {
        let verificationFactory = VerificationFactory(configuration: configuration)
        do {
            return try await verificationFactory.createVerificationService(
                primaryProvider: aiProvider,
                evidenceRepository: evidenceRepository
            )
        } catch {
            print("⚠️ [ApplicationFactory] VerificationService creation failed: \(error)")
            return nil
        }
    }
}

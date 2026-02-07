import AIPRDEncryptionEngine
import AIPRDOrchestrationEngine
import AIPRDRAGEngine
import AIPRDSharedUtilities
import AIPRDVerificationEngine
import Application
import Foundation
import InfrastructureCore

/// Channel-agnostic factory for creating application dependencies
/// Used by CLI, REST, and WebSocket factories
public final class ApplicationFactory: @unchecked Sendable {
    let configuration: Configuration
    let repositoryFactory: RepositoryFactory
    let aiComponentsFactory: AIComponentsFactory
    let prdUseCaseFactory: PRDUseCaseFactory
    let clarificationFactory: ClarificationUseCaseFactory
    let useCaseBuilder: ApplicationUseCaseBuilder
    var cachedDependencies: FactoryDependencies?
    var cachedPromptService: PromptEngineeringService?
    private var cachedVerifier: LLMResponseVerifier?
    private var cachedUnifiedEngine: UnifiedVerificationEngine?
    var repositoryConnection: RepositoryConnectionPort?
    var codebaseRepository: CodebaseRepositoryPort?

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
    public func createCustomGeneratePRDUseCase(
        interactionHandler: UserInteractionPort
    ) async -> GeneratePRDUseCase {
        guard let dependencies = cachedDependencies else {
            fatalError("Must call createUseCases() before creating custom use cases")
        }

        let components = buildCustomUseCaseComponents(dependencies: dependencies)
        let unifiedEngine = await getUnifiedVerificationEngine(aiProvider: dependencies.aiProvider)
        let llmVerifier = getLLMResponseVerifier(
            unifiedEngine: unifiedEngine,
            intelligenceTracker: components.intelligenceTracker
        )

        let config = GeneratePRDUseCaseConfig(
            mockupRepository: dependencies.mockupRepository,
            promptService: components.promptService,
            tokenizer: components.tokenizer,
            compressor: components.compressor,
            contextBuilder: components.contextBuilder,
            requirementAnalyzer: RequirementAnalyzerService(
                aiProvider: dependencies.aiProvider,
                intelligenceTracker: components.intelligenceTracker,
                verifier: llmVerifier
            ),
            interactionHandler: interactionHandler,
            intelligenceTracker: components.intelligenceTracker,
            unifiedEngine: unifiedEngine,
            llmVerifier: llmVerifier,
            licenseTier: configuration.licenseTier
        )
        return GeneratePRDUseCase(
            aiProvider: dependencies.aiProvider,
            prdRepository: dependencies.prdRepository,
            templateRepository: dependencies.templateRepository,
            config: config
        )
    }

    private func buildCustomUseCaseComponents(
        dependencies: FactoryDependencies
    ) -> CustomUseCaseComponents {
        let promptService = cachedPromptService ?? aiComponentsFactory.createPromptEngineeringService()
        let tokenizer = try? aiComponentsFactory.createTokenizer(for: configuration.aiProvider)
        let compressor: AppleIntelligenceContextCompressor?
        if let tokenizer = tokenizer {
            compressor = aiComponentsFactory.createCompressor(
                aiProvider: dependencies.aiProvider,
                tokenizer: tokenizer
            )
        } else {
            compressor = nil
        }
        let intelligenceTracker = getIntelligenceTracker()
        let contextBuilder = prdUseCaseFactory.createEnrichedContextBuilder(
            dependencies: dependencies,
            intelligenceTracker: intelligenceTracker
        )

        return CustomUseCaseComponents(
            promptService: promptService,
            tokenizer: tokenizer,
            compressor: compressor,
            intelligenceTracker: intelligenceTracker,
            contextBuilder: contextBuilder
        )
    }

    private func createDependencies() async throws -> FactoryDependencies {
        let prdRepository = try await repositoryFactory.createPRDRepository()
        let templateRepository = try await repositoryFactory.createTemplateRepository()
        let sessionRepository = try await repositoryFactory.createSessionRepository()
        let mockupRepository = try await repositoryFactory.createMockupRepository()
        let verificationRepo = try await repositoryFactory.createVerificationEvidenceRepository()
        let aiProvider = try await createAIProvider()

        try await repositoryFactory.seedDefaultTemplate(into: templateRepository)

        return FactoryDependencies(
            aiProvider: aiProvider,
            prdRepository: prdRepository,
            templateRepository: templateRepository,
            sessionRepository: sessionRepository,
            mockupRepository: mockupRepository,
            verificationEvidenceRepository: verificationRepo
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

        let factory = AIProviderFactory()
        let rawProvider = try await factory.createProvider(from: providerConfig)

        // Wrap with security if enabled
        if configuration.piiDetectionEnabled || configuration.injectionProtectionEnabled {
            let encryptionFactory = EncryptionFactory(configuration: configuration)
            let encryptionResult = encryptionFactory.createEncryptionEngine(aiProvider: rawProvider)

            if let engine = encryptionResult.engine {
                print("🔒 [ApplicationFactory] AI Provider wrapped with security (PII: \(configuration.piiDetectionEnabled), Injection: \(configuration.injectionProtectionEnabled))")
                return SecureAIProviderWrapper(
                    provider: rawProvider,
                    engine: engine,
                    auditLogger: nil,
                    blockOnSuspicious: false
                )
            } else {
                print("⚠️ [ApplicationFactory] Security degraded, using raw provider")
                return rawProvider
            }
        }

        return rawProvider
    }

    private func wireUseCases(
        dependencies: FactoryDependencies
    ) async throws -> ApplicationUseCases {
        let context = await createWiringContext(dependencies: dependencies)
        let core = try await createCoreUseCases(context: context)
        let extended = try await createExtendedUseCases(context: context)

        return assembleUseCases(
            generatePRD: core.generatePRD,
            listPRDs: core.listPRDs,
            getPRD: core.getPRD,
            sessionUseCases: core.sessionUseCases,
            clarificationUseCases: core.clarificationUseCases,
            analyzeRequest: extended.analyzeRequest,
            codebaseUseCases: extended.codebaseUseCases,
            integrationResult: extended.integrationResult
        )
    }

    private func assembleUseCases(
        generatePRD: GeneratePRDUseCase,
        listPRDs: ListPRDsUseCase,
        getPRD: GetPRDUseCase,
        sessionUseCases: (
            create: CreateSessionUseCase,
            continue: ContinueSessionUseCase,
            list: ListSessionsUseCase,
            get: GetSessionUseCase,
            delete: DeleteSessionUseCase
        ),
        clarificationUseCases: (
            base: ClarificationOrchestratorUseCase?,
            verified: VerifiedClarificationOrchestratorUseCase?
        ),
        analyzeRequest: AnalyzeRequestUseCase,
        codebaseUseCases: (
            create: CreateCodebaseUseCase?,
            index: IndexCodebaseUseCase?,
            list: ListCodebasesUseCase?,
            search: SearchCodebaseUseCase?,
            repository: CodebaseRepositoryPort?
        ),
        integrationResult: (
            connect: ConnectRepositoryProviderUseCase?,
            list: ListUserRepositoriesUseCase?,
            indexRemote: IndexRemoteRepositoryUseCase?,
            disconnect: DisconnectProviderUseCase?,
            listConnections: ListConnectionsUseCase?,
            connectionRepository: RepositoryConnectionPort?
        )
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

    func getUnifiedVerificationEngine(
        aiProvider: AIProviderPort
    ) async -> UnifiedVerificationEngine? {
        if let cached = cachedUnifiedEngine {
            return cached
        }

        let engine = await prdUseCaseFactory.createUnifiedVerificationEngineSafely(
            aiProvider: aiProvider,
            qualityTarget: VerificationQualityTarget.adaptive
        )

        if let engine = engine {
            cachedUnifiedEngine = engine
            print("✅ [ApplicationFactory] UnifiedVerificationEngine created (adaptive quality)")
        }

        return engine
    }

    func getLLMResponseVerifier(
        unifiedEngine: UnifiedVerificationEngine?,
        intelligenceTracker: IntelligenceTrackerService?
    ) -> LLMResponseVerifier {
        if let cached = cachedVerifier {
            return cached
        }

        let verifier = LLMResponseVerifier(
            unifiedEngine: unifiedEngine,
            intelligenceTracker: intelligenceTracker,
            verificationThreshold: 0.8
        )
        cachedVerifier = verifier
        print("✅ [ApplicationFactory] LLMResponseVerifier created (threshold: 80%)")
        return verifier
    }
}

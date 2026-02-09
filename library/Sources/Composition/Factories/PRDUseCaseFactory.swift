import AIPRDOrchestrationEngine
import AIPRDRAGEngine
import AIPRDSharedUtilities
import AIPRDStrategyEngine
import AIPRDVerificationEngine
import Application
import AIPRDSharedUtilities
import Foundation
import InfrastructureCore

/// Factory for creating PRD-related use cases
/// Extracted from ApplicationFactory to maintain file size limit
struct PRDUseCaseFactory {
    let configuration: Configuration
    let aiComponentsFactory: AIComponentsFactory
    let intelligenceFactory: IntelligenceFactory

    init(configuration: Configuration, aiComponentsFactory: AIComponentsFactory) {
        self.configuration = configuration
        self.aiComponentsFactory = aiComponentsFactory
        self.intelligenceFactory = IntelligenceFactory(configuration: configuration)
    }

    func createGeneratePRDUseCase(
        dependencies: FactoryDependencies,
        promptService: PromptEngineeringService,
        llmVerifier: LLMResponseVerifier? = nil,
        unifiedEngine: UnifiedVerificationEngine? = nil
    ) async -> GeneratePRDUseCase {
        let ragFactory = RAGFactory(configuration: configuration)
        let intelligenceTracker = createIntelligenceTrackerSafely()
        let components = createPRDComponents(
            dependencies: dependencies,
            ragFactory: ragFactory,
            intelligenceTracker: intelligenceTracker
        )
        let thinkingOrchestrator = createThinkingOrchestrator(
            aiProvider: dependencies.aiProvider,
            ragFactory: ragFactory,
            intelligenceTracker: intelligenceTracker
        )

        let engine = await resolveVerificationEngine(
            unifiedEngine: unifiedEngine,
            aiProvider: dependencies.aiProvider
        )

        let verifier = resolveVerifier(
            llmVerifier: llmVerifier,
            engine: engine,
            intelligenceTracker: intelligenceTracker
        )

        let coherenceScorer = createCoherenceScorer(
            aiProvider: dependencies.aiProvider,
            verifier: verifier
        )

        return buildGeneratePRDUseCase(
            dependencies: dependencies,
            components: components,
            promptService: promptService,
            thinkingOrchestrator: thinkingOrchestrator,
            intelligenceTracker: intelligenceTracker,
            coherenceScorer: coherenceScorer,
            engine: engine
        )
    }

    private func resolveVerificationEngine(
        unifiedEngine: UnifiedVerificationEngine?,
        aiProvider: AIProviderPort
    ) async -> UnifiedVerificationEngine? {
        if let providedEngine = unifiedEngine {
            return providedEngine
        }
        return await createUnifiedVerificationEngineSafely(
            aiProvider: aiProvider,
            qualityTarget: .adaptive
        )
    }

    private func resolveVerifier(
        llmVerifier: LLMResponseVerifier?,
        engine: UnifiedVerificationEngine?,
        intelligenceTracker: IntelligenceTrackerService?
    ) -> LLMResponseVerifier {
        llmVerifier ?? LLMResponseVerifier(
            unifiedEngine: engine,
            intelligenceTracker: intelligenceTracker,
            verificationThreshold: 0.8
        )
    }

    private func createCoherenceScorer(
        aiProvider: AIProviderPort,
        verifier: LLMResponseVerifier
    ) -> QuestionCoherenceScorer {
        QuestionCoherenceScorer(
            aiProvider: aiProvider,
            coherenceThreshold: 0.9,
            effectivenessThreshold: 0.8,
            verifier: verifier
        )
    }

    private func buildGeneratePRDUseCase(
        dependencies: FactoryDependencies,
        components: PRDComponents,
        promptService: PromptEngineeringService,
        thinkingOrchestrator: ThinkingOrchestratorUseCase,
        intelligenceTracker: IntelligenceTrackerService?,
        coherenceScorer: QuestionCoherenceScorer,
        engine: UnifiedVerificationEngine?
    ) -> GeneratePRDUseCase {
        let config = GeneratePRDUseCaseConfig(
            codebaseRepository: components.codebaseRepository,
            embeddingGenerator: components.embeddingGenerator,
            mockupRepository: dependencies.mockupRepository,
            promptService: promptService,
            tokenizer: components.tokenizer,
            compressor: components.compressor,
            contextBuilder: components.contextBuilder,
            requirementAnalyzer: RequirementAnalyzerService(
                aiProvider: dependencies.aiProvider,
                intelligenceTracker: intelligenceTracker,
                verifier: LLMResponseVerifier(
                    unifiedEngine: engine,
                    intelligenceTracker: intelligenceTracker,
                    verificationThreshold: 0.8
                )
            ),
            interactionHandler: aiComponentsFactory.createInteractionHandler(),
            thinkingOrchestrator: thinkingOrchestrator,
            intelligenceTracker: intelligenceTracker,
            coherenceScorer: coherenceScorer,
            unifiedEngine: engine,
            licenseTier: configuration.licenseTier
        )
        return GeneratePRDUseCase(
            aiProvider: dependencies.aiProvider,
            prdRepository: dependencies.prdRepository,
            templateRepository: dependencies.templateRepository,
            config: config
        )
    }

    private func createPRDComponents(
        dependencies: FactoryDependencies,
        ragFactory: RAGFactory,
        intelligenceTracker: IntelligenceTrackerService?
    ) -> PRDComponents {
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
        let contextBuilder = createEnrichedContextBuilder(
            dependencies: dependencies,
            ragFactory: ragFactory,
            intelligenceTracker: intelligenceTracker
        )
        return PRDComponents(
            tokenizer: tokenizer,
            compressor: compressor,
            contextBuilder: contextBuilder,
            codebaseRepository: try? ragFactory.createCodebaseRepository(),
            embeddingGenerator: ragFactory.createEmbeddingGenerator()
        )
    }

    private func createIntelligenceTrackerSafely() -> IntelligenceTrackerService? {
        do {
            let tracker = try intelligenceFactory.createIntelligenceTracker()
            print("✅ [PRDUseCaseFactory] IntelligenceTracker created")
            return tracker
        } catch {
            print("⚠️ [PRDUseCaseFactory] IntelligenceTracker failed: \(error)")
            return nil
        }
    }

    func createUnifiedVerificationEngineSafely(
        aiProvider: AIProviderPort,
        qualityTarget: VerificationQualityTarget = .adaptive
    ) async -> UnifiedVerificationEngine? {
        let verificationFactory = VerificationFactory(configuration: configuration)
        let result = await verificationFactory.createUnifiedEngine(
            primaryProvider: aiProvider,
            qualityTarget: qualityTarget
        )

        if case .unified(let engine) = result {
            print("✅ [PRDUseCaseFactory] UnifiedVerificationEngine created")
            return engine
        }

        print("⚠️ [PRDUseCaseFactory] UnifiedVerificationEngine failed - using degraded mode")
        return nil
    }

    func createEnrichedContextBuilder(
        dependencies: FactoryDependencies,
        ragFactory: RAGFactory? = nil,
        intelligenceTracker: IntelligenceTrackerService? = nil
    ) -> EnrichedContextBuilder? {
        let factory = ragFactory ?? RAGFactory(configuration: configuration)
        let thinkingOrchestrator = createThinkingOrchestrator(
            aiProvider: dependencies.aiProvider,
            ragFactory: factory,
            intelligenceTracker: intelligenceTracker
        )

        let ragResult = factory.createRAGEngineWithFallback(aiProvider: dependencies.aiProvider)
        let ragEngine = ragResult.engine

        var codebaseRepo: CodebaseRepositoryPort?
        do {
            codebaseRepo = try factory.createCodebaseRepository()
            print("✅ [PRDUseCaseFactory] CodebaseRepository created successfully")
        } catch {
            print("⚠️ [PRDUseCaseFactory] Failed to create CodebaseRepository: \(error)")
        }

        if !ragResult.isEngineMode {
            print("⚠️ [PRDUseCaseFactory] RAG in degraded mode - using basic search fallback")
        }

        var visionAnalyzer: VisionAnalysisPort?
        if #available(iOS 26.0, macOS 26.0, *) {
            visionAnalyzer = aiComponentsFactory.createVisionAnalyzer()
        }

        // Create on-demand GitHub fetcher for repository URL support
        let httpClient = HTTPClient()
        let onDemandFetcher = GitHubOnDemandFetcher(httpClient: httpClient)
        print("✅ [PRDUseCaseFactory] GitHubOnDemandFetcher created")

        return EnrichedContextBuilder(
            ragEngine: ragEngine,
            reasoningOrchestrator: thinkingOrchestrator,
            visionAnalyzer: visionAnalyzer,
            mockupRepository: dependencies.mockupRepository,
            codebaseRepository: codebaseRepo,
            onDemandFetcher: onDemandFetcher,
            intelligenceTracker: intelligenceTracker
        )
    }

    private func createThinkingOrchestrator(
        aiProvider: AIProviderPort,
        ragFactory: RAGFactory,
        intelligenceTracker: IntelligenceTrackerService? = nil
    ) -> ThinkingOrchestratorUseCase {
        let ragResult = ragFactory.createRAGEngineWithFallback(aiProvider: aiProvider)
        let ragOrchestrator = try? ragFactory.createContextRetrievalOrchestrator(aiProvider: aiProvider)

        let strategyFactory = StrategyFactory(configuration: configuration)
        let strategyResult = strategyFactory.createStrategyEngineAdapter()

        return ThinkingOrchestratorUseCase(
            aiProvider: aiProvider,
            ragEngine: ragResult.engine,
            ragOrchestrator: ragOrchestrator,
            intelligenceTracker: intelligenceTracker,
            strategyEngineAdapter: strategyResult.adapter,
            licenseTier: configuration.licenseTier
        )
    }
}

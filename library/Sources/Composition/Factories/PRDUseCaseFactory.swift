import Foundation
import Domain
import Application
import InfrastructureCore

/// Factory for creating PRD-related use cases
/// Extracted from ApplicationFactory to maintain file size limit
struct PRDUseCaseFactory {
    private let configuration: Configuration
    private let aiComponentsFactory: AIComponentsFactory
    private let intelligenceFactory: IntelligenceFactory

    init(configuration: Configuration, aiComponentsFactory: AIComponentsFactory) {
        self.configuration = configuration
        self.aiComponentsFactory = aiComponentsFactory
        self.intelligenceFactory = IntelligenceFactory(configuration: configuration)
    }

    func createGeneratePRDUseCase(
        dependencies: FactoryDependencies,
        promptService: PromptEngineeringService
    ) async -> GeneratePRDUseCase {
        let ragFactory = RAGFactory(configuration: configuration)
        // Create intelligence tracker FIRST so it can be shared with context builder
        let intelligenceTracker = createIntelligenceTrackerSafely()
        let components = createPRDComponents(
            dependencies: dependencies, ragFactory: ragFactory, intelligenceTracker: intelligenceTracker
        )
        let thinkingOrchestrator = createThinkingOrchestrator(
            aiProvider: dependencies.aiProvider, ragFactory: ragFactory, intelligenceTracker: intelligenceTracker
        )

        // Create coherence scorer for filtering questions BEFORE asking
        // Both thresholds must pass: coherence >= 0.9, effectiveness >= 0.8 (against feature description)
        let coherenceScorer = QuestionCoherenceScorer(
            aiProvider: dependencies.aiProvider,
            coherenceThreshold: 0.9,
            effectivenessThreshold: 0.8
        )

        // Create verification service for multi-judge evaluation
        let verificationService = await createVerificationServiceSafely(
            aiProvider: dependencies.aiProvider,
            evidenceRepository: dependencies.verificationEvidenceRepository
        )

        return GeneratePRDUseCase(
            aiProvider: dependencies.aiProvider,
            prdRepository: dependencies.prdRepository,
            templateRepository: dependencies.templateRepository,
            codebaseRepository: components.codebaseRepository,
            embeddingGenerator: components.embeddingGenerator,
            mockupRepository: dependencies.mockupRepository,
            promptService: promptService,
            tokenizer: components.tokenizer,
            compressor: components.compressor,
            contextExtractor: SectionContextExtractor(),
            contextBuilder: components.contextBuilder,
            requirementAnalyzer: RequirementAnalyzerService(
                aiProvider: dependencies.aiProvider,
                intelligenceTracker: intelligenceTracker
            ),
            interactionHandler: aiComponentsFactory.createInteractionHandler(),
            thinkingOrchestrator: thinkingOrchestrator,
            intelligenceTracker: intelligenceTracker,
            coherenceScorer: coherenceScorer,
            verificationService: verificationService
        )
    }

    private func createPRDComponents(
        dependencies: FactoryDependencies,
        ragFactory: RAGFactory,
        intelligenceTracker: IntelligenceTrackerService?
    ) -> PRDComponents {
        let tokenizer = aiComponentsFactory.createTokenizer(for: configuration.aiProvider)
        let compressor = aiComponentsFactory.createCompressor(aiProvider: dependencies.aiProvider, tokenizer: tokenizer)
        let contextBuilder = createEnrichedContextBuilder(
            dependencies: dependencies, ragFactory: ragFactory, intelligenceTracker: intelligenceTracker
        )
        return PRDComponents(
            tokenizer: tokenizer, compressor: compressor, contextBuilder: contextBuilder,
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

    private func createVerificationServiceSafely(
        aiProvider: AIProviderPort,
        evidenceRepository: VerificationEvidenceRepositoryPort?
    ) async -> ChainOfVerificationService? {
        let verificationFactory = VerificationFactory(configuration: configuration)
        do {
            let service = try await verificationFactory.createVerificationService(
                primaryProvider: aiProvider,
                evidenceRepository: evidenceRepository
            )
            print("✅ [PRDUseCaseFactory] VerificationService created")
            return service
        } catch {
            print("⚠️ [PRDUseCaseFactory] VerificationService failed: \(error)")
            return nil
        }
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

        // Create RAG components with explicit error handling and logging
        var hybridSearch: HybridSearchService?
        var codebaseRepo: CodebaseRepositoryPort?

        do {
            hybridSearch = try factory.createHybridSearchService()
            print("✅ [PRDUseCaseFactory] HybridSearchService created successfully")
        } catch {
            print("⚠️ [PRDUseCaseFactory] Failed to create HybridSearchService: \(error)")
        }

        do {
            codebaseRepo = try factory.createCodebaseRepository()
            print("✅ [PRDUseCaseFactory] CodebaseRepository created successfully")
        } catch {
            print("⚠️ [PRDUseCaseFactory] Failed to create CodebaseRepository: \(error)")
        }

        if hybridSearch == nil {
            print("⚠️ [PRDUseCaseFactory] No HybridSearchService - codebase RAG will be disabled")
        }

        var visionAnalyzer: VisionAnalysisPort?
        if #available(iOS 15.0, macOS 12.0, *) {
            visionAnalyzer = aiComponentsFactory.createVisionAnalyzer()
        }

        return EnrichedContextBuilder(
            hybridSearch: hybridSearch,
            reasoningOrchestrator: thinkingOrchestrator,
            visionAnalyzer: visionAnalyzer,
            mockupRepository: dependencies.mockupRepository,
            codebaseRepository: codebaseRepo,
            intelligenceTracker: intelligenceTracker
        )
    }

    private func createThinkingOrchestrator(
        aiProvider: AIProviderPort,
        ragFactory: RAGFactory,
        intelligenceTracker: IntelligenceTrackerService? = nil
    ) -> ThinkingOrchestratorUseCase {
        let codebaseRepository = try? ragFactory.createCodebaseRepository()
        let embeddingGenerator = ragFactory.createEmbeddingGenerator()

        return ThinkingOrchestratorUseCase(
            aiProvider: aiProvider,
            codebaseRepository: codebaseRepository,
            embeddingGenerator: embeddingGenerator,
            intelligenceTracker: intelligenceTracker
        )
    }
}

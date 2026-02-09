import AIPRDSharedUtilities
import AIPRDRAGEngine
import Foundation
import AIPRDSharedUtilities
import Application
import InfrastructureCore

/// Factory for creating codebase-related use cases
/// Following Single Responsibility: Handles codebase use case creation
struct CodebaseUseCaseFactory: Sendable {
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func createUseCases(aiProvider: AIProviderPort) throws -> (
        create: CreateCodebaseUseCase?,
        index: IndexCodebaseUseCase?,
        list: ListCodebasesUseCase?,
        search: SearchCodebaseUseCase?,
        repository: CodebaseRepositoryPort?
    ) {
        let ragFactory = RAGFactory(configuration: configuration)

        guard let codebaseRepository = try ragFactory.createCodebaseRepository(),
              let embeddingGenerator = ragFactory.createEmbeddingGenerator(),
              let ragEngine = try ragFactory.createRAGEngine(aiProvider: aiProvider) else {
            return (nil, nil, nil, nil, nil)
        }

        let codeParser = MultiLanguageCodeParser()
        let hashingService = CryptoKitHashingAdapter()

        // Enable contextual retrieval for +49% precision improvement (optional, requires AI provider + tokenizer)
        let contextualEnricher = ragFactory.createContextualEnricher(aiProvider: aiProvider)

        let create = CreateCodebaseUseCase(repository: codebaseRepository)
        let index = IndexCodebaseUseCase(
            codebaseRepository: codebaseRepository,
            codeParser: codeParser,
            embeddingGenerator: embeddingGenerator,
            hashingService: hashingService,
            contextualEnricher: contextualEnricher
        )
        let list = ListCodebasesUseCase(repository: codebaseRepository)
        let search = SearchCodebaseUseCase(ragEngine: ragEngine)

        return (create, index, list, search, codebaseRepository)
    }
}

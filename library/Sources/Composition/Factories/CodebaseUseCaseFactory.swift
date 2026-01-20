import Foundation
import Domain
import Application
import InfrastructureCore

/// Factory for creating codebase-related use cases
/// Following Single Responsibility: Handles codebase use case creation
struct CodebaseUseCaseFactory: Sendable {
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func createUseCases() throws -> (
        create: CreateCodebaseUseCase?,
        index: IndexCodebaseUseCase?,
        list: ListCodebasesUseCase?,
        search: SearchCodebaseUseCase?,
        repository: CodebaseRepositoryPort?
    ) {
        let ragFactory = RAGFactory(configuration: configuration)

        guard let codebaseRepository = try ragFactory.createCodebaseRepository(),
              let embeddingGenerator = ragFactory.createEmbeddingGenerator(),
              let hybridSearch = try ragFactory.createHybridSearchService() else {
            return (nil, nil, nil, nil, nil)
        }

        let codeParser = MultiLanguageCodeParser()
        let hashingService = CryptoKitHashingAdapter()

        let create = CreateCodebaseUseCase(repository: codebaseRepository)
        let index = IndexCodebaseUseCase(
            codebaseRepository: codebaseRepository,
            codeParser: codeParser,
            embeddingGenerator: embeddingGenerator,
            hashingService: hashingService
        )
        let list = ListCodebasesUseCase(repository: codebaseRepository)
        let search = SearchCodebaseUseCase(hybridSearch: hybridSearch)

        return (create, index, list, search, codebaseRepository)
    }
}

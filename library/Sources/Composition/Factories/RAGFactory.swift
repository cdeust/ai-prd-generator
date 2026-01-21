import Foundation
import Domain
import Application
import InfrastructureCore

/// Factory for creating RAG infrastructure components
/// Following Single Responsibility: Handles RAG-specific dependency creation
struct RAGFactory: Sendable {
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func createCodebaseRepository() throws -> CodebaseRepositoryPort? {
        // Standalone skill: Only support PostgreSQL (Docker/local) for RAG
        switch configuration.storageType {
        case .postgres:
            let databaseClient = try createPostgreSQLDatabaseClient()
            return PostgreSQLCodebaseRepository(databaseClient: databaseClient)
        case .memory, .filesystem:
            return nil
        }
    }

    func createEmbeddingGenerator() -> EmbeddingGeneratorPort? {
        if #available(iOS 16.0, macOS 13.0, *) {
            return NaturalLanguageEmbeddings(
                embeddingDimension: 1536,
                modelIdentifier: "natural-language-default"
            )
        } else {
            return nil
        }
    }

    func createFullTextSearch() throws -> FullTextSearchPort? {
        // Standalone skill: Use PostgreSQL for full-text search (BM25)
        switch configuration.storageType {
        case .postgres:
            let databaseClient = try createPostgreSQLDatabaseClient()
            return PostgreSQLFullTextSearch(databaseClient: databaseClient)
        case .memory, .filesystem:
            return nil
        }
    }

    func createHybridSearchService() throws -> HybridSearchService? {
        guard let codebaseRepository = try createCodebaseRepository(),
              let embeddingGenerator = createEmbeddingGenerator(),
              let fullTextSearch = try createFullTextSearch() else {
            return nil
        }

        return HybridSearchService(
            codebaseRepository: codebaseRepository,
            embeddingGenerator: embeddingGenerator,
            fullTextSearch: fullTextSearch
        )
    }

    private func createPostgreSQLDatabaseClient() throws -> PostgreSQLDatabasePort {
        guard let databaseURL = configuration.databaseURL else {
            throw ConfigurationError.missingDatabaseURL
        }

        let client = PostgreSQLClient()
        Task {
            try await client.connect(connectionString: databaseURL)
        }
        return client
    }
}

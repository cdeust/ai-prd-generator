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
        switch configuration.storageType {
        case .supabase:
            let databaseClient = try createSupabaseDatabaseClient()
            return SupabaseCodebaseRepository(databaseClient: databaseClient)
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
        switch configuration.storageType {
        case .supabase:
            let databaseClient = try createSupabaseDatabaseClient()
            return PostgreSQLFullTextSearch(databaseClient: databaseClient)
        case .postgres:
            // TODO: Implement PostgreSQLFullTextSearch for local PostgreSQL
            // For now, return nil (hybrid search will use vector search only)
            return nil
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

    private func createSupabaseDatabaseClient() throws -> SupabaseDatabasePort {
        guard let urlString = configuration.supabaseURL,
              let url = URL(string: urlString),
              let key = configuration.supabaseKey else {
            throw ConfigurationError.missingSupabaseCredentials
        }

        // Use long-running client for database operations (indexing can take 30+ minutes)
        let httpClient = HTTPClient.longRunning()
        let supabaseClient = SupabaseClient(projectURL: url, apiKey: key, httpClient: httpClient)
        return SupabaseDatabaseClient(supabaseClient: supabaseClient)
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

import AIPRDOrchestrationEngine
import AIPRDRAGEngine
import AIPRDSharedUtilities
import Application
import AIPRDSharedUtilities
import Foundation
import InfrastructureCore

/// Factory for creating RAG infrastructure components
/// Following Single Responsibility: Handles RAG-specific dependency creation
struct RAGFactory: Sendable {
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    /// Create RAG engine with automatic fallback to degraded mode
    /// - Parameter aiProvider: AI provider for query expansion and reranking
    /// - Returns: Either full engine or degraded service
    func createRAGEngineWithFallback(aiProvider: AIProviderPort) -> RAGServiceResult {
        do {
            if let engine = try createRAGEngine(aiProvider: aiProvider) {
                print("✅ [RAGFactory] Full RAG Engine loaded")
                return .engine(engine)
            } else {
                print("⚠️ [RAGFactory] RAG Engine components unavailable")
                print("   Using degraded search mode")
                return .degraded(DegradedRAGService())
            }
        } catch {
            print("⚠️ [RAGFactory] RAG Engine creation failed: \(error)")
            print("   Using degraded search mode")
            return .degraded(DegradedRAGService())
        }
    }

    /// Create degraded RAG service (basic search fallback)
    /// Use when full engine is not available
    func createDegradedRAGService() -> DegradedRAGService {
        print("⚠️ [RAGFactory] Creating degraded RAG service")
        return DegradedRAGService()
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
        if #available(iOS 26.0, macOS 26.0, *) {
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

    func createRAGEngine(aiProvider: AIProviderPort) throws -> RAGEngineProtocol? {
        guard let codebaseRepository = try createCodebaseRepository(),
              let embeddingGenerator = createEmbeddingGenerator(),
              let fullTextSearch = try createFullTextSearch() else {
            return nil
        }

        return RAGEngine(
            codebaseRepository: codebaseRepository,
            embeddingGenerator: embeddingGenerator,
            fullTextSearch: fullTextSearch,
            aiProvider: aiProvider
        )
    }

    func createContextRetrievalOrchestrator(
        aiProvider: AIProviderPort
    ) throws -> ContextRetrievalOrchestrator? {
        guard let codebaseRepository = try createCodebaseRepository(),
              let embeddingGenerator = createEmbeddingGenerator(),
              let fullTextSearch = try createFullTextSearch() else {
            return nil
        }

        let hybridSearch = HybridSearchService(
            codebaseRepository: codebaseRepository,
            embeddingGenerator: embeddingGenerator,
            fullTextSearch: fullTextSearch
        )
        let queryExpander = QueryExpansionService(aiProvider: aiProvider)
        let reranker = RerankingService(aiProvider: aiProvider)

        return ContextRetrievalOrchestrator(
            hybridSearch: hybridSearch,
            queryExpander: queryExpander,
            reranker: reranker,
            aiProvider: aiProvider
        )
    }

    func createContextualEnricher(aiProvider: AIProviderPort) -> (any ChunkEnricherPort)? {
        // Create tokenizer for the AI provider
        guard let tokenizer = createTokenizer(for: configuration.aiProvider) else {
            return nil
        }

        return AnthropicContextualEnricher(
            aiProvider: aiProvider,
            tokenizer: tokenizer
        )
    }

    private func createTokenizer(for provider: AIProviderType) -> TokenizerPort? {
        switch provider {
        case .anthropic:
            return try? ClaudeTokenizer()
        case .bedrock:
            return try? BedrockTokenizer()
        case .openAI:
            return try? OpenAITokenizer()
        case .openRouter:
            return OpenRouterTokenizer()
        case .appleFoundationModels:
            if #available(iOS 26.0, macOS 26.0, *) {
                return AppleTokenizer()
            }
            return nil
        case .gemini:
            return GeminiTokenizer()
        case .qwen, .zhipu, .moonshot, .minimax, .deepseek:
            return try? OpenAITokenizer()
        }
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

import AIPRDEncryptionEngine
import AIPRDRAGEngine
import AIPRDSharedUtilities
import AIPRDStrategyEngine
import Application
import Foundation

/// Public interface to the Business Layer (Protected Core)
/// This is the ONLY interface that Presenter Layer microservices should know
///
/// Usage (from Gateway microservice):
/// ```swift
/// let composition = try await LibraryComposition.create(
///     databaseURL: Environment.get("DATABASE_URL"),
///     aiProviders: .default
/// )
///
/// // Call Business Layer via interface
/// let result = try await composition.useCases.generatePRD.execute(...)
/// ```
public struct LibraryComposition: Sendable {
    /// Use cases (business operations)
    public let useCases: ApplicationUseCases

    /// Shared services
    public let services: SharedServices

    /// Repositories (for advanced integration scenarios)
    public let repositories: CompositionRepositories

    public init(
        useCases: ApplicationUseCases,
        services: SharedServices,
        repositories: CompositionRepositories = CompositionRepositories()
    ) {
        self.useCases = useCases
        self.services = services
        self.repositories = repositories
    }

    /// Create LibraryComposition with default configuration
    /// This method wires up all layers internally (Presenter Layer doesn't see this)
    public static func create(
        configuration: Configuration
    ) async throws -> LibraryComposition {
        // Delegate to ApplicationFactory (internal implementation)
        let factory = ApplicationFactory(configuration: configuration)
        let useCases = try await factory.createUseCases()

        // Shared services with factory for custom use cases
        let useCaseFactory = UseCaseFactory(applicationFactory: factory)
        let intelligenceTracker = factory.getIntelligenceTracker()
        let githubIntegration = factory.getGitHubIntegration()
        let ragResult = factory.getRAGEngineWithMode()
        let strategyResult = factory.getStrategyEngineAdapterWithMode()
        let encryptionResult = factory.getEncryptionEngineWithMode()
        let services = SharedServices(
            ragEngine: ragResult.engine,
            isRAGDegraded: !ragResult.isEngineMode,
            strategyEngine: strategyResult.adapter,
            isStrategyDegraded: !strategyResult.isLicensed,
            encryptionEngine: encryptionResult.engine,
            isEncryptionDegraded: encryptionResult.isDegraded,
            factory: useCaseFactory,
            intelligenceTracker: intelligenceTracker,
            githubIntegration: githubIntegration
        )

        // Repositories
        let connectionRepository = factory.getRepositoryConnection()
        let mockupRepository = factory.getMockupRepository()
        let codebaseRepository = factory.getCodebaseRepository()
        let repositories = CompositionRepositories(
            repositoryConnection: connectionRepository,
            mockupRepository: mockupRepository,
            codebase: codebaseRepository
        )

        return LibraryComposition(
            useCases: useCases,
            services: services,
            repositories: repositories
        )
    }

    /// Convenience method for creating with environment variables
    public static func createFromEnvironment() async throws -> LibraryComposition {
        let configuration = Configuration.fromEnvironment()
        return try await create(configuration: configuration)
    }
}

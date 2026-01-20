import Foundation
import Domain
import Application

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
    public let repositories: Repositories

    /// Shared application services exposed to presenters
    public struct SharedServices: Sendable {
        public let hybridSearch: HybridSearchService?
        public let factory: UseCaseFactory?
        public let intelligenceTracker: IntelligenceTrackerService?

        public init(
            hybridSearch: HybridSearchService?,
            factory: UseCaseFactory? = nil,
            intelligenceTracker: IntelligenceTrackerService? = nil
        ) {
            self.hybridSearch = hybridSearch
            self.factory = factory
            self.intelligenceTracker = intelligenceTracker
        }
    }

    /// Repositories for advanced integration scenarios
    public struct Repositories: Sendable {
        public let repositoryConnection: RepositoryConnectionPort?
        public let mockupRepository: MockupRepositoryPort?
        public let codebase: CodebaseRepositoryPort?

        public init(
            repositoryConnection: RepositoryConnectionPort? = nil,
            mockupRepository: MockupRepositoryPort? = nil,
            codebase: CodebaseRepositoryPort? = nil
        ) {
            self.repositoryConnection = repositoryConnection
            self.mockupRepository = mockupRepository
            self.codebase = codebase
        }
    }

    /// Factory for creating use cases with custom dependencies
    public struct UseCaseFactory: Sendable {
        private let applicationFactory: ApplicationFactory

        internal init(applicationFactory: ApplicationFactory) {
            self.applicationFactory = applicationFactory
        }

        /// Create GeneratePRDUseCase with custom interaction handler
        public func createGeneratePRDUseCase(
            interactionHandler: UserInteractionPort
        ) async -> GeneratePRDUseCase {
            return await applicationFactory.createCustomGeneratePRDUseCase(
                interactionHandler: interactionHandler
            )
        }

        /// Create vision analyzer for mockup analysis
        @available(iOS 15.0, macOS 12.0, *)
        public func createVisionAnalyzer() -> VisionAnalysisPort? {
            return applicationFactory.getVisionAnalyzer()
        }
    }

    public init(
        useCases: ApplicationUseCases,
        services: SharedServices,
        repositories: Repositories = Repositories()
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
        let services = SharedServices(
            hybridSearch: nil,
            factory: useCaseFactory,
            intelligenceTracker: intelligenceTracker
        )

        // Repositories
        let connectionRepository = factory.getRepositoryConnection()
        let mockupRepository = factory.getMockupRepository()
        let codebaseRepository = factory.getCodebaseRepository()
        let repositories = Repositories(
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

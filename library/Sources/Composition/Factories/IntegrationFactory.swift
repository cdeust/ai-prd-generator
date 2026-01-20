import Foundation
import Domain
import Application
import InfrastructureCore

/// Factory for creating repository integration dependencies
/// Handles GitHub/Bitbucket OAuth and repository fetching
internal final class IntegrationFactory {
    private let configuration: Configuration
    private let repositoryFactory: RepositoryFactory

    init(configuration: Configuration, repositoryFactory: RepositoryFactory) {
        self.configuration = configuration
        self.repositoryFactory = repositoryFactory
    }

    /// Create integration use cases if OAuth is configured
    func createIntegrationUseCases(
        codebaseRepository: CodebaseRepositoryPort?,
        createCodebase: CreateCodebaseUseCase?,
        indexCodebase: IndexCodebaseUseCase?
    ) async throws -> (
        connect: ConnectRepositoryProviderUseCase?,
        list: ListUserRepositoriesUseCase?,
        indexRemote: IndexRemoteRepositoryUseCase?,
        disconnect: DisconnectProviderUseCase?,
        listConnections: ListConnectionsUseCase?,
        connectionRepository: RepositoryConnectionPort?
    ) {
        // Check if GitHub or Bitbucket OAuth is configured
        guard configuration.hasOAuthConfiguration else {
            return (nil, nil, nil, nil, nil, nil)
        }

        // Create adapters
        let connectionRepository = try await createConnectionRepository()
        let oauthClient = createOAuthClient()
        let repositoryFetcher = createRepositoryFetcher()

        // Create use cases
        let connect = ConnectRepositoryProviderUseCase(
            connectionRepository: connectionRepository,
            oauthClient: oauthClient,
            repositoryFetcher: repositoryFetcher
        )

        let list = ListUserRepositoriesUseCase(
            connectionRepository: connectionRepository,
            repositoryFetcher: repositoryFetcher,
            oauthClient: oauthClient
        )

        let listConnections = ListConnectionsUseCase(
            connectionRepository: connectionRepository
        )

        let disconnect = DisconnectProviderUseCase(
            connectionRepository: connectionRepository
        )

        // Only create index if codebase use cases and repository exist
        let indexRemote: IndexRemoteRepositoryUseCase?
        if let codebaseRepository = codebaseRepository,
           let createCodebase = createCodebase,
           let indexCodebase = indexCodebase {
            indexRemote = IndexRemoteRepositoryUseCase(
                connectionRepository: connectionRepository,
                codebaseRepository: codebaseRepository,
                repositoryFetcher: repositoryFetcher,
                oauthClient: oauthClient,
                createCodebase: createCodebase,
                indexCodebase: indexCodebase
            )
        } else {
            indexRemote = nil
        }

        return (connect, list, indexRemote, disconnect, listConnections, connectionRepository)
    }

    private func createConnectionRepository() async throws -> RepositoryConnectionPort {
        // Use Supabase if configured, otherwise fail
        guard let supabaseURLString = configuration.supabaseURL,
              let url = URL(string: supabaseURLString),
              let key = configuration.supabaseKey else {
            throw ConfigurationError.missingSupabaseCredentials
        }

        // Use long-running client for database operations during indexing
        let httpClient = HTTPClient.longRunning()
        let supabaseClient = SupabaseClient(projectURL: url, apiKey: key, httpClient: httpClient)
        let databaseClient = SupabaseDatabaseClient(supabaseClient: supabaseClient)

        return SupabaseRepositoryConnectionRepository(client: databaseClient)
    }

    private func createOAuthClient() -> OAuthClientPort {
        // Use long-running client for OAuth token operations
        let httpClient = HTTPClient.longRunning()
        return StandardOAuthClient(httpClient: httpClient)
    }

    private func createRepositoryFetcher() -> RepositoryFetcherPort {
        // Use long-running client for repository fetching (large repos can take 30+ minutes)
        let httpClient = HTTPClient.longRunning()
        return GitHubRepositoryFetcher(httpClient: httpClient)
    }
}

/// Extension to check OAuth configuration
extension Configuration {
    var hasOAuthConfiguration: Bool {
        // Check if either GitHub or Bitbucket client ID/secret is set
        let githubClientId = ProcessInfo.processInfo.environment["GITHUB_CLIENT_ID"]
        let bitbucketClientId = ProcessInfo.processInfo.environment["BITBUCKET_CLIENT_ID"]

        // Also need Supabase for storing connections
        return (githubClientId != nil || bitbucketClientId != nil) &&
               supabaseURL != nil && supabaseKey != nil
    }
}

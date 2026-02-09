import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities
import Application
import InfrastructureCore

/// Factory for creating repository integration dependencies
/// For standalone skill: OAuth integrations DISABLED (use gh CLI instead)
internal final class IntegrationFactory {
    private let configuration: Configuration
    private let repositoryFactory: RepositoryFactory

    init(configuration: Configuration, repositoryFactory: RepositoryFactory) {
        self.configuration = configuration
        self.repositoryFactory = repositoryFactory
    }

    /// Integration use cases disabled for standalone skill
    /// Use `gh auth login` for GitHub instead of OAuth
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
        // OAuth integration disabled for standalone skill
        // Use GitHub CLI (gh auth login) instead
        return (nil, nil, nil, nil, nil, nil)
    }
}

/// Extension to check OAuth configuration
extension Configuration {
    var hasOAuthConfiguration: Bool {
        // OAuth disabled for standalone skill
        return false
    }
}

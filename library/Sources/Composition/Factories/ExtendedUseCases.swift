import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import Application
import AIPRDSharedUtilities
import Foundation

/// Extended use cases created during application wiring
/// Contains codebase management and repository integration use cases
struct ExtendedUseCases {
    let codebaseUseCases: (
        create: CreateCodebaseUseCase?,
        index: IndexCodebaseUseCase?,
        list: ListCodebasesUseCase?,
        search: SearchCodebaseUseCase?,
        repository: CodebaseRepositoryPort?
    )
    let integrationResult: (
        connect: ConnectRepositoryProviderUseCase?,
        list: ListUserRepositoriesUseCase?,
        indexRemote: IndexRemoteRepositoryUseCase?,
        disconnect: DisconnectProviderUseCase?,
        listConnections: ListConnectionsUseCase?,
        connectionRepository: RepositoryConnectionPort?
    )
    let analyzeRequest: AnalyzeRequestUseCase
}

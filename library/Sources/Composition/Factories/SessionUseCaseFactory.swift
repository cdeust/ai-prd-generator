import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities
import Application

/// Factory for creating session-related use cases
/// Following Single Responsibility: Handles session use case creation
struct SessionUseCaseFactory: Sendable {
    func createUseCases(
        repository: SessionRepositoryPort,
        generatePRD: GeneratePRDUseCase
    ) -> (
        create: CreateSessionUseCase,
        continue: ContinueSessionUseCase,
        list: ListSessionsUseCase,
        get: GetSessionUseCase,
        delete: DeleteSessionUseCase
    ) {
        (
            CreateSessionUseCase(repository: repository),
            ContinueSessionUseCase(sessionRepository: repository, generatePRD: generatePRD),
            ListSessionsUseCase(repository: repository),
            GetSessionUseCase(repository: repository),
            DeleteSessionUseCase(repository: repository)
        )
    }
}

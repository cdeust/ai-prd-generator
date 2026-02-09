import AIPRDOrchestrationEngine
import Application
import Foundation

/// Core use cases created during application wiring
/// Contains the essential PRD generation and session management use cases
struct CoreUseCases {
    let generatePRD: GeneratePRDUseCase
    let listPRDs: ListPRDsUseCase
    let getPRD: GetPRDUseCase
    let sessionUseCases: (
        create: CreateSessionUseCase,
        continue: ContinueSessionUseCase,
        list: ListSessionsUseCase,
        get: GetSessionUseCase,
        delete: DeleteSessionUseCase
    )
    let clarificationUseCases: (
        base: ClarificationOrchestratorUseCase?,
        verified: VerifiedClarificationOrchestratorUseCase?
    )
}

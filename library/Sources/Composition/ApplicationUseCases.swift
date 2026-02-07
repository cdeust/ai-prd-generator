import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import Foundation
import Application

/// Container for application use cases
/// Used by all presentation channels (CLI, REST, WebSocket)
public struct ApplicationUseCases: Sendable {
    public let generatePRD: GeneratePRDUseCase
    public let listPRDs: ListPRDsUseCase
    public let getPRD: GetPRDUseCase
    public let createSession: CreateSessionUseCase
    public let continueSession: ContinueSessionUseCase
    public let listSessions: ListSessionsUseCase
    public let getSession: GetSessionUseCase
    public let deleteSession: DeleteSessionUseCase
    public let clarificationOrchestrator: ClarificationOrchestratorUseCase?
    public let verifiedClarificationOrchestrator: VerifiedClarificationOrchestratorUseCase?
    public let analyzeRequest: AnalyzeRequestUseCase?

    // Codebase operations (optional - requires PostgreSQL configuration)
    public let createCodebase: CreateCodebaseUseCase?
    public let indexCodebase: IndexCodebaseUseCase?
    public let listCodebases: ListCodebasesUseCase?
    public let searchCodebase: SearchCodebaseUseCase?

    // Repository integration (optional - requires OAuth configuration)
    public let connectRepositoryProvider: ConnectRepositoryProviderUseCase?
    public let listUserRepositories: ListUserRepositoriesUseCase?
    public let indexRemoteRepository: IndexRemoteRepositoryUseCase?
    public let disconnectProvider: DisconnectProviderUseCase?
    public let listConnections: ListConnectionsUseCase?

    public init(
        generatePRD: GeneratePRDUseCase,
        listPRDs: ListPRDsUseCase,
        getPRD: GetPRDUseCase,
        createSession: CreateSessionUseCase,
        continueSession: ContinueSessionUseCase,
        listSessions: ListSessionsUseCase,
        getSession: GetSessionUseCase,
        deleteSession: DeleteSessionUseCase,
        clarificationOrchestrator: ClarificationOrchestratorUseCase? = nil,
        verifiedClarificationOrchestrator: VerifiedClarificationOrchestratorUseCase? = nil,
        analyzeRequest: AnalyzeRequestUseCase? = nil,
        createCodebase: CreateCodebaseUseCase? = nil,
        indexCodebase: IndexCodebaseUseCase? = nil,
        listCodebases: ListCodebasesUseCase? = nil,
        searchCodebase: SearchCodebaseUseCase? = nil,
        connectRepositoryProvider: ConnectRepositoryProviderUseCase? = nil,
        listUserRepositories: ListUserRepositoriesUseCase? = nil,
        indexRemoteRepository: IndexRemoteRepositoryUseCase? = nil,
        disconnectProvider: DisconnectProviderUseCase? = nil,
        listConnections: ListConnectionsUseCase? = nil
    ) {
        self.generatePRD = generatePRD
        self.listPRDs = listPRDs
        self.getPRD = getPRD
        self.createSession = createSession
        self.continueSession = continueSession
        self.listSessions = listSessions
        self.getSession = getSession
        self.deleteSession = deleteSession
        self.clarificationOrchestrator = clarificationOrchestrator
        self.verifiedClarificationOrchestrator = verifiedClarificationOrchestrator
        self.analyzeRequest = analyzeRequest
        self.createCodebase = createCodebase
        self.indexCodebase = indexCodebase
        self.listCodebases = listCodebases
        self.searchCodebase = searchCodebase
        self.connectRepositoryProvider = connectRepositoryProvider
        self.listUserRepositories = listUserRepositories
        self.indexRemoteRepository = indexRemoteRepository
        self.disconnectProvider = disconnectProvider
        self.listConnections = listConnections
    }
}

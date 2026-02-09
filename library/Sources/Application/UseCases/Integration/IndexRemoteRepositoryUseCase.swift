import AIPRDSharedUtilities
import AIPRDSharedUtilities
import Foundation

/// Use case for indexing a remote repository
/// Fetches repository files and indexes them using existing pipeline
public struct IndexRemoteRepositoryUseCase: Sendable {
    private let connectionRepository: RepositoryConnectionPort
    private let codebaseRepository: CodebaseRepositoryPort
    private let repositoryFetcher: RepositoryFetcherPort
    private let oauthClient: OAuthClientPort
    private let createCodebase: CreateCodebaseUseCase
    private let indexCodebase: IndexCodebaseUseCase

    public init(
        connectionRepository: RepositoryConnectionPort,
        codebaseRepository: CodebaseRepositoryPort,
        repositoryFetcher: RepositoryFetcherPort,
        oauthClient: OAuthClientPort,
        createCodebase: CreateCodebaseUseCase,
        indexCodebase: IndexCodebaseUseCase
    ) {
        self.connectionRepository = connectionRepository
        self.codebaseRepository = codebaseRepository
        self.repositoryFetcher = repositoryFetcher
        self.oauthClient = oauthClient
        self.createCodebase = createCodebase
        self.indexCodebase = indexCodebase
    }

    /// Execute repository indexing - creates codebase immediately and starts indexing in background
    public func execute(
        connectionId: UUID,
        repositoryUrl: String,
        branch: String?,
        clientId: String,
        clientSecret: String
    ) async throws -> IndexingResult {
        let connection = try await getValidConnection(
            connectionId: connectionId, clientId: clientId, clientSecret: clientSecret
        )

        let repository = try RepositoryURLParser.parse(repositoryUrl, provider: connection.provider)
        let branchName = branch ?? repository.defaultBranch

        if let existing = try await findExistingCodebase(url: repositoryUrl, branch: branchName) {
            return IndexingResult(codebase: existing, isNewIndexing: false)
        }

        let codebase = try await createCodebase.execute(
            userId: connection.userId,
            name: repository.name,
            repositoryUrl: repositoryUrl,
            localPath: nil,
            initialStatus: .inProgress
        )

        let project = try await createProject(
            codebase: codebase,
            repositoryUrl: repositoryUrl,
            branch: branchName
        )

        startBackgroundIndexing(
            codebase: codebase, project: project, repository: repository,
            branchName: branchName, connection: connection, connectionId: connectionId
        )

        return IndexingResult(codebase: codebase, isNewIndexing: true)
    }

    private func startBackgroundIndexing(
        codebase: Codebase,
        project: CodebaseProject,
        repository: RemoteRepository,
        branchName: String,
        connection: RepositoryConnection,
        connectionId: UUID
    ) {
        let codebaseRepo = codebaseRepository
        let connRepo = connectionRepository
        let indexUseCase = indexCodebase
        let fetcher = repositoryFetcher

        Task.detached {
            await Self.performBackgroundIndexing(
                codebase: codebase, project: project, repository: repository,
                branchName: branchName, connection: connection, connectionId: connectionId,
                codebaseRepo: codebaseRepo, connRepo: connRepo,
                indexUseCase: indexUseCase, fetcher: fetcher
            )
        }
    }

    private static func performBackgroundIndexing(
        codebase: Codebase,
        project: CodebaseProject,
        repository: RemoteRepository,
        branchName: String,
        connection: RepositoryConnection,
        connectionId: UUID,
        codebaseRepo: CodebaseRepositoryPort,
        connRepo: RepositoryConnectionPort,
        indexUseCase: IndexCodebaseUseCase,
        fetcher: RepositoryFetcherPort
    ) async {
        do {
            let filesWithContent = try await RepositoryContentFetcher.fetchFiles(
                repository: repository, branch: branchName, connection: connection,
                codebaseId: codebase.id, projectId: project.id, fetcher: fetcher
            )

            try await indexUseCase.execute(
                codebaseId: codebase.id,
                projectId: project.id,
                files: filesWithContent
            )
            try await connRepo.updateLastSync(connectionId: connectionId, date: Date())
            try await CodebaseStatusUpdater.updateStatus(
                codebaseId: codebase.id,
                status: .completed,
                repository: codebaseRepo
            )
        } catch {
            try? await codebaseRepo.updateProjectIndexingError(
                projectId: project.id,
                error: error.localizedDescription
            )
            try? await CodebaseStatusUpdater.updateStatus(
                codebaseId: codebase.id,
                status: .failed,
                repository: codebaseRepo
            )
        }
    }

    private func findExistingCodebase(url: String, branch: String) async throws -> Codebase? {
        guard let existingProject = try await codebaseRepository.findProjectByRepository(
            url: url,
            branch: branch
        ) else {
            return nil
        }
        return try await codebaseRepository.getCodebase(by: existingProject.codebaseId)
    }

    private func createProject(
        codebase: Codebase,
        repositoryUrl: String,
        branch: String
    ) async throws -> CodebaseProject {
        let project = CodebaseProject(
            codebaseId: codebase.id,
            name: codebase.name,
            repositoryUrl: repositoryUrl,
            branch: branch,
            indexingStatus: .inProgress,
            indexingStartedAt: Date()
        )
        return try await codebaseRepository.saveProject(project)
    }

    private func getValidConnection(
        connectionId: UUID,
        clientId: String,
        clientSecret: String
    ) async throws -> RepositoryConnection {
        guard var connection = try await connectionRepository.findConnection(id: connectionId) else {
            throw OAuthError.invalidConnection
        }

        if connection.isExpired, connection.refreshToken != nil {
            connection = try await ConnectionTokenRefresher.refresh(
                connection: connection,
                clientId: clientId,
                clientSecret: clientSecret,
                oauthClient: oauthClient,
                connectionRepository: connectionRepository
            )
        }

        return connection
    }
}

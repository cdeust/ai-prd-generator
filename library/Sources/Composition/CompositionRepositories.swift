import AIPRDRAGEngine
import AIPRDSharedUtilities
import Application
import AIPRDSharedUtilities
import Foundation

/// Repositories for advanced integration scenarios
public struct CompositionRepositories: Sendable {
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

import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Use case for listing codebases
/// Following SRP - handles codebase retrieval
/// Following DIP - depends on repository port
public struct ListCodebasesUseCase: Sendable {
    private let repository: CodebaseRepositoryPort

    public init(repository: CodebaseRepositoryPort) {
        self.repository = repository
    }

    public func execute(forUser userId: UUID, limit: Int = 100, offset: Int = 0) async throws -> [Codebase] {
        return try await repository.listCodebases(forUser: userId)
    }
}

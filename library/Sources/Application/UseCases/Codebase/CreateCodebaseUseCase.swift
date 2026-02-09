import AIPRDSharedUtilities
import Foundation

/// Use case for creating a new codebase
/// Following SRP - handles codebase creation logic
/// Following DIP - depends on repository port only
public struct CreateCodebaseUseCase: Sendable {
    private let repository: CodebaseRepositoryPort

    public init(repository: CodebaseRepositoryPort) {
        self.repository = repository
    }

    public func execute(
        userId: UUID,
        name: String,
        repositoryUrl: String? = nil,
        localPath: String? = nil,
        initialStatus: IndexingStatus = .pending
    ) async throws -> Codebase {
        // Validate input
        guard !name.isEmpty else {
            throw ValidationError.custom("Codebase name cannot be empty")
        }

        // Create codebase entity
        let codebase = Codebase(
            userId: userId,
            name: name,
            repositoryUrl: repositoryUrl,
            localPath: localPath,
            indexingStatus: initialStatus
        )

        // Save via repository port
        return try await repository.createCodebase(codebase)
    }
}

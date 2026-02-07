import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Use case for deleting a session
/// Following SRP - deletes session
/// Following DIP - depends on repository port
public struct DeleteSessionUseCase: Sendable {
    private let repository: SessionRepositoryPort

    public init(repository: SessionRepositoryPort) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws {
        try await repository.delete(id)
    }
}

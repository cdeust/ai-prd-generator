import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Use case for retrieving a session by ID
/// Following SRP - retrieves single session
/// Following DIP - depends on repository port
public struct GetSessionUseCase: Sendable {
    private let repository: SessionRepositoryPort

    public init(repository: SessionRepositoryPort) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws -> Session? {
        return try await repository.findById(id)
    }
}

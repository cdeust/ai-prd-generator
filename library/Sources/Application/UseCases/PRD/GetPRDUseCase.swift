import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Use case for retrieving a PRD
/// Following SRP - retrieves PRD by ID
/// Following DIP - depends on repository port
public struct GetPRDUseCase: Sendable {
    private let repository: PRDRepositoryPort

    public init(repository: PRDRepositoryPort) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws -> PRDDocument? {
        return try await repository.findById(id)
    }
}

import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Use case for listing sessions
/// Following SRP - retrieves list of sessions
/// Following DIP - depends on repository port
public struct ListSessionsUseCase: Sendable {
    private let repository: SessionRepositoryPort

    public init(repository: SessionRepositoryPort) {
        self.repository = repository
    }

    public func execute(activeOnly: Bool = false) async throws -> [Session] {
        if activeOnly {
            return try await repository.findActive()
        } else {
            return try await repository.findAll()
        }
    }
}

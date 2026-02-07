import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Use case for listing PRDs
/// Following SRP - retrieves list of PRDs
/// Following DIP - depends on repository port
public struct ListPRDsUseCase: Sendable {
    private let repository: PRDRepositoryPort

    public init(repository: PRDRepositoryPort) {
        self.repository = repository
    }

    public func execute(limit: Int = 50, offset: Int = 0) async throws -> [PRDDocument] {
        return try await repository.findAll(limit: limit, offset: offset)
    }
}

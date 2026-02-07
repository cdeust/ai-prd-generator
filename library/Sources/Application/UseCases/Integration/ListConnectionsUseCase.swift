import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Use case for listing user's repository connections
/// Returns all OAuth connections for a user
public struct ListConnectionsUseCase: Sendable {
    private let connectionRepository: RepositoryConnectionPort

    public init(connectionRepository: RepositoryConnectionPort) {
        self.connectionRepository = connectionRepository
    }

    public func execute(
        userId: UUID,
        provider: RepositoryProvider? = nil
    ) async throws -> [RepositoryConnection] {
        return try await connectionRepository.findConnections(
            userId: userId,
            provider: provider
        )
    }
}

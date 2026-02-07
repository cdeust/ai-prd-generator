import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Use case for disconnecting a repository provider
/// Removes OAuth connection from database
public struct DisconnectProviderUseCase: Sendable {
    private let connectionRepository: RepositoryConnectionPort

    public init(connectionRepository: RepositoryConnectionPort) {
        self.connectionRepository = connectionRepository
    }

    public func execute(connectionId: UUID) async throws {
        try await connectionRepository.deleteConnection(id: connectionId)
    }
}

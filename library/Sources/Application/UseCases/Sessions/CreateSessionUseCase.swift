import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Use case for creating a new session
/// Following SRP - creates and persists new session
/// Following DIP - depends on repository port
public struct CreateSessionUseCase: Sendable {
    private let repository: SessionRepositoryPort

    public init(repository: SessionRepositoryPort) {
        self.repository = repository
    }

    public func execute(
        userId: UUID,
        title: String? = nil,
        description: String = "",
        tags: [String] = []
    ) async throws -> Session {
        var metadata = SessionMetadata()

        if let title = title {
            metadata.title = title
        }

        metadata.description = description
        metadata.tags = tags

        let session = Session(
            id: UUID(),
            userId: userId,
            startTime: Date(),
            messages: [],
            metadata: metadata
        )

        return try await repository.create(session)
    }
}

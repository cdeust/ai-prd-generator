import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Use case for retrieving a PRD template by ID
/// Single Responsibility: Fetch template
public struct GetTemplateUseCase: Sendable {
    private let repository: PRDTemplateRepositoryPort

    public init(repository: PRDTemplateRepositoryPort) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws -> PRDTemplate? {
        try await repository.findById(id)
    }
}

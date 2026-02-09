import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Use case for deleting a PRD template
/// Single Responsibility: Delete template with validation
public struct DeleteTemplateUseCase: Sendable {
    private let repository: PRDTemplateRepositoryPort

    public init(repository: PRDTemplateRepositoryPort) {
        self.repository = repository
    }

    public func execute(id: UUID) async throws {
        guard let template = try await repository.findById(id) else {
            throw ValidationError.custom("Template not found")
        }

        guard !template.isDefault else {
            throw ValidationError.custom(
                "Cannot delete default template"
            )
        }

        try await repository.delete(id)
    }
}

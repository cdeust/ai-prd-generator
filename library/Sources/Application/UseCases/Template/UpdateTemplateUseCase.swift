import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Use case for updating an existing PRD template
/// Single Responsibility: Update template with validation
public struct UpdateTemplateUseCase: Sendable {
    private let repository: PRDTemplateRepositoryPort

    public init(repository: PRDTemplateRepositoryPort) {
        self.repository = repository
    }

    public func execute(
        id: UUID,
        name: String,
        description: String,
        sections: [TemplateSectionConfig],
        isDefault: Bool
    ) async throws -> PRDTemplate {
        guard let existing = try await repository.findById(id) else {
            throw ValidationError.custom("Template not found")
        }

        try await validateUniqueNameIfChanged(
            newName: name,
            existingName: existing.name
        )

        let updated = PRDTemplate(
            id: id,
            name: name,
            description: description,
            sections: sections,
            isDefault: isDefault,
            createdAt: existing.createdAt,
            updatedAt: Date()
        )

        try updated.validate()

        return try await repository.save(updated)
    }

    private func validateUniqueNameIfChanged(
        newName: String,
        existingName: String
    ) async throws {
        guard newName != existingName else { return }

        let exists = try await repository.existsByName(newName)
        guard !exists else {
            throw ValidationError.custom(
                "Template with name '\(newName)' already exists"
            )
        }
    }
}

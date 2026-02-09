import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Use case for creating a new PRD template
/// Single Responsibility: Create and validate template
public struct CreateTemplateUseCase: Sendable {
    private let repository: PRDTemplateRepositoryPort

    public init(repository: PRDTemplateRepositoryPort) {
        self.repository = repository
    }

    public func execute(
        name: String,
        description: String,
        sections: [TemplateSectionConfig],
        isDefault: Bool = false
    ) async throws -> PRDTemplate {
        try await validateUniqueName(name)

        let template = PRDTemplate(
            name: name,
            description: description,
            sections: sections,
            isDefault: isDefault
        )

        try template.validate()

        return try await repository.save(template)
    }

    private func validateUniqueName(_ name: String) async throws {
        let exists = try await repository.existsByName(name)
        guard !exists else {
            throw ValidationError.custom(
                "Template with name '\(name)' already exists"
            )
        }
    }
}

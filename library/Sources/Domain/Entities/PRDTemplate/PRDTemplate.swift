import Foundation

/// Domain entity representing a reusable PRD template
/// Single Responsibility: Define structure and configuration for PRD generation
public struct PRDTemplate: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let description: String
    public let sections: [TemplateSectionConfig]
    public let isDefault: Bool
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        sections: [TemplateSectionConfig],
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.sections = sections
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var orderedSections: [TemplateSectionConfig] {
        sections.sorted { $0.order < $1.order }
    }

    public var requiredSections: [TemplateSectionConfig] {
        sections.filter { $0.isRequired }
    }

    public func validate() throws {
        try validateName()
        try validateDescription()
        try validateSections()
        try validateDates()
    }

    private func validateName() throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.missingRequired(field: "name")
        }
    }

    private func validateDescription() throws {
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.missingRequired(field: "description")
        }
    }

    private func validateSections() throws {
        guard !sections.isEmpty else {
            throw ValidationError.custom(
                "Template must have at least one section"
            )
        }

        for section in sections {
            try section.validate()
        }

        try validateUniqueSectionOrders()
        try validateUniqueSectionTypes()
    }

    private func validateUniqueSectionOrders() throws {
        let orders = sections.map { $0.order }
        let uniqueOrders = Set(orders)

        guard orders.count == uniqueOrders.count else {
            throw ValidationError.custom(
                "Section orders must be unique"
            )
        }
    }

    private func validateUniqueSectionTypes() throws {
        let types = sections.map { $0.sectionType }
        let uniqueTypes = Set(types)

        guard types.count == uniqueTypes.count else {
            throw ValidationError.custom(
                "Section types must be unique"
            )
        }
    }

    private func validateDates() throws {
        guard updatedAt >= createdAt else {
            throw ValidationError.custom(
                "updatedAt cannot be before createdAt"
            )
        }
    }
}

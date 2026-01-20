import Foundation

/// Port for PRD template persistence
/// Domain defines the interface, Infrastructure implements it
public protocol PRDTemplateRepositoryPort: Sendable {
    /// Save a new template or update existing
    func save(_ template: PRDTemplate) async throws -> PRDTemplate

    /// Find template by ID
    func findById(_ id: UUID) async throws -> PRDTemplate?

    /// List all templates
    func findAll() async throws -> [PRDTemplate]

    /// List default templates only
    func findDefaults() async throws -> [PRDTemplate]

    /// Delete template by ID
    func delete(_ id: UUID) async throws

    /// Check if template name already exists
    func existsByName(_ name: String) async throws -> Bool
}

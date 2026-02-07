import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// In-memory implementation of PRDTemplateRepositoryPort
/// For testing, demos, and rapid prototyping
/// Thread-safe using actor isolation
public actor InMemoryPRDTemplateRepository: PRDTemplateRepositoryPort {
    private var templates: [UUID: PRDTemplate] = [:]

    public init() {}

    public func save(_ template: PRDTemplate) async throws -> PRDTemplate {
        templates[template.id] = template
        return template
    }

    public func findById(_ id: UUID) async throws -> PRDTemplate? {
        return templates[id]
    }

    public func findAll() async throws -> [PRDTemplate] {
        return Array(templates.values.sorted { $0.name < $1.name })
    }

    public func findDefaults() async throws -> [PRDTemplate] {
        return templates.values
            .filter { $0.isDefault }
            .sorted { $0.name < $1.name }
    }

    public func delete(_ id: UUID) async throws {
        guard templates[id] != nil else {
            throw RepositoryError.invalidQuery("Template not found: \(id)")
        }

        templates.removeValue(forKey: id)
    }

    public func existsByName(_ name: String) async throws -> Bool {
        return templates.values.contains { $0.name == name }
    }
}

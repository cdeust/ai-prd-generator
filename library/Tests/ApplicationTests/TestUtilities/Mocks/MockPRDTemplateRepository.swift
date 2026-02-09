import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// In-memory mock PRD template repository for testing
public actor MockPRDTemplateRepository: PRDTemplateRepositoryPort {
    private var templates: [UUID: PRDTemplate] = [:]
    private var shouldFail = false
    private var failureError: Error?

    public init() {}

    // MARK: - Configuration

    public func configure(shouldFail: Bool, error: Error? = nil) {
        self.shouldFail = shouldFail
        self.failureError = error
    }

    public func reset() {
        templates.removeAll()
        shouldFail = false
        failureError = nil
    }

    public func seed(templates: [PRDTemplate]) {
        for template in templates {
            self.templates[template.id] = template
        }
    }

    // MARK: - PRDTemplateRepositoryPort

    public func save(_ template: PRDTemplate) async throws -> PRDTemplate {
        if shouldFail {
            throw failureError ?? MockRepositoryError.configured
        }

        templates[template.id] = template
        return template
    }

    public func findById(_ id: UUID) async throws -> PRDTemplate? {
        if shouldFail {
            throw failureError ?? MockRepositoryError.configured
        }
        return templates[id]
    }

    public func findAll() async throws -> [PRDTemplate] {
        if shouldFail {
            throw failureError ?? MockRepositoryError.configured
        }
        return Array(templates.values)
    }

    public func findDefaults() async throws -> [PRDTemplate] {
        if shouldFail {
            throw failureError ?? MockRepositoryError.configured
        }
        return templates.values.filter { $0.isDefault }
    }

    public func delete(_ id: UUID) async throws {
        if shouldFail {
            throw failureError ?? MockRepositoryError.configured
        }
        templates.removeValue(forKey: id)
    }

    public func existsByName(_ name: String) async throws -> Bool {
        if shouldFail {
            throw failureError ?? MockRepositoryError.configured
        }
        return templates.values.contains { $0.name == name }
    }
}

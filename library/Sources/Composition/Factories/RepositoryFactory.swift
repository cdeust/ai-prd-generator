import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities
import Application
import InfrastructureCore

/// Factory responsible for creating repository implementations
/// Extracted from ApplicationFactory to maintain Single Responsibility
public final class RepositoryFactory {
    private let configuration: Configuration

    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    public func createPRDRepository() async throws -> PRDRepositoryPort {
        // Standalone skill: Always use in-memory for PRD documents
        // (PRDs are generated on-demand, no need for persistence)
        return InMemoryPRDRepository()
    }

    public func createSessionRepository() async throws -> SessionRepositoryPort {
        // Standalone skill: Always use in-memory for sessions
        // (Sessions are transient, no need for persistence)
        return InMemorySessionRepository()
    }

    public func createTemplateRepository() async throws -> PRDTemplateRepositoryPort {
        // Standalone skill: Always use in-memory for templates
        // (Templates are loaded from code, no need for database)
        return InMemoryPRDTemplateRepository()
    }

    public func createMockupRepository() async throws -> MockupRepositoryPort {
        // Standalone skill: Always use in-memory for mockups
        // (Mockups are analyzed and discarded, no need for persistence)
        return InMemoryMockupRepository()
    }

    public func createVerificationEvidenceRepository() async throws -> VerificationEvidenceRepositoryPort {
        // Standalone skill: Always use in-memory for verification evidence
        // (Verification results are included in PRD output, no need for persistence)
        return InMemoryVerificationEvidenceRepository()
    }

    public func seedDefaultTemplate(
        into repository: PRDTemplateRepositoryPort
    ) async throws {
        let defaultTemplate = DefaultPRDTemplate.create()

        // Check if template already exists to avoid duplicate key error
        do {
            let exists = try await repository.existsByName(defaultTemplate.name)
            guard !exists else {
                print("📋 [RepositoryFactory] Default template already exists")
                return
            }
            _ = try await repository.save(defaultTemplate)
            print("✅ [RepositoryFactory] Default template seeded")
        } catch {
            // Gracefully handle duplicate key or other errors - seeding is non-critical
            print("⚠️ [RepositoryFactory] Template seeding skipped: \(error)")
        }
    }
}

import Foundation
import Domain
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
        switch configuration.storageType {
        case .memory, .filesystem, .postgres:
            // For local PostgreSQL, use in-memory for now (PRD not critical for MCP skill)
            return InMemoryPRDRepository()
        case .supabase:
            let databaseClient = try createSupabaseDatabaseClient()
            return SupabasePRDRepository(databaseClient: databaseClient)
        }
    }

    public func createSessionRepository() async throws -> SessionRepositoryPort {
        switch configuration.storageType {
        case .memory, .filesystem, .postgres:
            // For local PostgreSQL, use in-memory for now (sessions not critical for MCP skill)
            return InMemorySessionRepository()
        case .supabase:
            let databaseClient = try createSupabaseDatabaseClient()
            return SupabaseSessionRepository(client: databaseClient)
        }
    }

    public func createTemplateRepository() async throws -> PRDTemplateRepositoryPort {
        switch configuration.storageType {
        case .memory, .filesystem, .postgres:
            // For local PostgreSQL, use in-memory for now (templates not critical for MCP skill)
            return InMemoryPRDTemplateRepository()
        case .supabase:
            let supabaseClient = try createSupabaseClient()
            return SupabasePRDTemplateRepository(client: supabaseClient)
        }
    }

    public func createMockupRepository() async throws -> MockupRepositoryPort {
        switch configuration.storageType {
        case .memory, .filesystem, .postgres:
            // For local PostgreSQL, use in-memory for now (mockups not critical for MCP skill)
            return InMemoryMockupRepository()
        case .supabase:
            let databaseClient = try createSupabaseDatabaseClient()
            return SupabaseMockupRepository(databaseClient: databaseClient)
        }
    }

    public func createVerificationEvidenceRepository() async throws -> VerificationEvidenceRepositoryPort {
        switch configuration.storageType {
        case .memory, .filesystem, .postgres:
            // For local PostgreSQL and non-database storage, use in-memory
            return InMemoryVerificationEvidenceRepository()
        case .supabase:
            let databaseClient = try createSupabaseDatabaseClient()
            return SupabaseVerificationEvidenceRepository(databaseClient: databaseClient)
        }
    }

    private func createSupabaseClient() throws -> SupabaseClient {
        guard let urlString = configuration.supabaseURL,
              let url = URL(string: urlString),
              let key = configuration.supabaseKey else {
            throw ConfigurationError.missingSupabaseCredentials
        }
        return SupabaseClient(projectURL: url, apiKey: key)
    }

    private func createSupabaseDatabaseClient() throws -> SupabaseDatabasePort {
        guard let urlString = configuration.supabaseURL,
              let url = URL(string: urlString),
              let key = configuration.supabaseKey else {
            throw ConfigurationError.missingSupabaseCredentials
        }

        let supabaseClient = SupabaseClient(projectURL: url, apiKey: key)
        return SupabaseDatabaseClient(supabaseClient: supabaseClient)
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

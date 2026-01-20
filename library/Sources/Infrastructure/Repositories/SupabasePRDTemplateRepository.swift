import Foundation
import Domain

/// Supabase implementation of PRDTemplateRepositoryPort
/// Single Responsibility: Persist and retrieve PRD templates from Supabase
public actor SupabasePRDTemplateRepository: PRDTemplateRepositoryPort {
    private let client: SupabaseClient
    private let tableName = "prd_templates"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func save(_ template: PRDTemplate) async throws -> PRDTemplate {
        let record = SupabasePRDTemplateMapper.toRecord(template)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(record)

        let response: [SupabasePRDTemplateRecord] = try await client.execute(
            method: .post,
            path: "/\(tableName)",
            body: data
        )

        guard let saved = response.first else {
            throw RepositoryError.saveFailed("No record returned")
        }

        return try SupabasePRDTemplateMapper.toDomain(saved)
    }

    public func findById(_ id: UUID) async throws -> PRDTemplate? {
        let queryItems = [
            URLQueryItem(name: "id", value: "eq.\(id.uuidString)"),
            URLQueryItem(name: "select", value: "*")
        ]

        let records: [SupabasePRDTemplateRecord] = try await client.execute(
            method: .get,
            path: "/\(tableName)",
            queryItems: queryItems
        )

        guard let record = records.first else {
            return nil
        }

        return try SupabasePRDTemplateMapper.toDomain(record)
    }

    public func findAll() async throws -> [PRDTemplate] {
        let queryItems = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]

        let records: [SupabasePRDTemplateRecord] = try await client.execute(
            method: .get,
            path: "/\(tableName)",
            queryItems: queryItems
        )

        return try records.map(SupabasePRDTemplateMapper.toDomain)
    }

    public func findDefaults() async throws -> [PRDTemplate] {
        let queryItems = [
            URLQueryItem(name: "is_default", value: "eq.true"),
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]

        let records: [SupabasePRDTemplateRecord] = try await client.execute(
            method: .get,
            path: "/\(tableName)",
            queryItems: queryItems
        )

        return try records.map(SupabasePRDTemplateMapper.toDomain)
    }

    public func delete(_ id: UUID) async throws {
        let queryItems = [
            URLQueryItem(name: "id", value: "eq.\(id.uuidString)")
        ]

        let _: [SupabasePRDTemplateRecord] = try await client.execute(
            method: .delete,
            path: "/\(tableName)",
            queryItems: queryItems
        )
    }

    public func existsByName(_ name: String) async throws -> Bool {
        let queryItems = [
            URLQueryItem(name: "name", value: "eq.\(name)"),
            URLQueryItem(name: "select", value: "id")
        ]

        // Use minimal struct to avoid decoding issues with sections JSONB
        let records: [TemplateIdOnly] = try await client.execute(
            method: .get,
            path: "/\(tableName)",
            queryItems: queryItems
        )

        return !records.isEmpty
    }
}

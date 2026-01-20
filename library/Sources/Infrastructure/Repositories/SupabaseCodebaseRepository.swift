import Foundation
import Domain

/// Update struct for project indexing error
private struct ProjectIndexingErrorUpdate: Encodable {
    let indexingStatus: String
    let indexingError: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case indexingStatus = "indexing_status"
        case indexingError = "indexing_error"
        case updatedAt = "updated_at"
    }
}

/// Supabase implementation of Codebase Repository
/// Single Responsibility: Codebase persistence via Supabase
/// Following naming: Supabase{Domain}Repository
public final class SupabaseCodebaseRepository: CodebaseRepositoryPort {
    internal let databaseClient: SupabaseDatabasePort
    internal let mapper: SupabaseCodebaseMapper

    public init(databaseClient: SupabaseDatabasePort) {
        self.databaseClient = databaseClient
        self.mapper = SupabaseCodebaseMapper()
    }

    // MARK: - Codebase Operations

    public func createCodebase(_ codebase: Codebase) async throws -> Codebase {
        let record = mapper.codebaseToRecord(codebase)
        // Use upsert to handle duplicate repository URLs - updates existing if conflict
        let data = try await databaseClient.upsert(
            table: "codebases",
            values: record,
            onConflict: ["user_id", "repository_url"]
        )
        let savedRecord = try decode([SupabaseCodebaseRecord].self, from: data).first!
        return mapper.codebaseToDomain(savedRecord)
    }

    public func getCodebase(by id: UUID) async throws -> Codebase? {
        let filter = QueryFilter(field: "id", operation: .equals, value: id.uuidString)
        let data = try await databaseClient.select(from: "codebases", columns: nil, filter: filter)
        let records = try decode([SupabaseCodebaseRecord].self, from: data)
        return records.first.map { mapper.codebaseToDomain($0) }
    }

    public func listCodebases(forUser userId: UUID) async throws -> [Codebase] {
        let filter = QueryFilter(field: "user_id", operation: .equals, value: userId.uuidString)
        let data = try await databaseClient.select(from: "codebases", columns: nil, filter: filter)
        let records = try decode([SupabaseCodebaseRecord].self, from: data)
        return records.map { mapper.codebaseToDomain($0) }
    }

    public func updateCodebase(_ codebase: Codebase) async throws -> Codebase {
        let record = mapper.codebaseToRecord(codebase)
        let filter = QueryFilter(field: "id", operation: .equals, value: codebase.id.uuidString)
        let data = try await databaseClient.update(table: "codebases", values: record, matching: filter)
        let updatedRecord = try decode([SupabaseCodebaseRecord].self, from: data).first!
        return mapper.codebaseToDomain(updatedRecord)
    }

    public func deleteCodebase(_ id: UUID) async throws {
        let filter = QueryFilter(field: "id", operation: .equals, value: id.uuidString)
        try await databaseClient.delete(from: "codebases", matching: filter)
    }

    // MARK: - Codebase Project Operations

    public func saveProject(_ project: CodebaseProject) async throws -> CodebaseProject {
        let record = mapper.projectToRecord(project)
        let data = try await databaseClient.insert(table: "codebase_projects", values: record)
        let savedRecord = try decode([SupabaseCodebaseProjectRecord].self, from: data).first!
        return mapper.projectToDomain(savedRecord)
    }

    public func findProjectById(_ id: UUID) async throws -> CodebaseProject? {
        let filter = QueryFilter(field: "id", operation: .equals, value: id.uuidString)
        let data = try await databaseClient.select(from: "codebase_projects", columns: nil, filter: filter)
        let records = try decode([SupabaseCodebaseProjectRecord].self, from: data)
        return records.first.map { mapper.projectToDomain($0) }
    }

    public func findProjectByRepository(url: String, branch: String) async throws -> CodebaseProject? {
        let filter = QueryFilter(field: "repository_url", operation: .equals, value: url)
        let data = try await databaseClient.select(from: "codebase_projects", columns: nil, filter: filter)
        let records = try decode([SupabaseCodebaseProjectRecord].self, from: data)
        return records
            .first { $0.branch == branch }
            .map { mapper.projectToDomain($0) }
    }

    public func updateProject(_ project: CodebaseProject) async throws -> CodebaseProject {
        let record = mapper.projectToRecord(project)
        let filter = QueryFilter(field: "id", operation: .equals, value: project.id.uuidString)
        let data = try await databaseClient.update(
            table: "codebase_projects",
            values: record,
            matching: filter
        )
        let updatedRecord = try decode([SupabaseCodebaseProjectRecord].self, from: data).first!
        return mapper.projectToDomain(updatedRecord)
    }

    public func deleteProject(_ id: UUID) async throws {
        let filter = QueryFilter(field: "id", operation: .equals, value: id.uuidString)
        try await databaseClient.delete(from: "codebase_projects", matching: filter)
    }

    public func updateProjectIndexingError(projectId: UUID, error: String) async throws {
        let filter = QueryFilter(field: "id", operation: .equals, value: projectId.uuidString)
        let updateValues = ProjectIndexingErrorUpdate(
            indexingStatus: "failed",
            indexingError: error,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        _ = try await databaseClient.update(table: "codebase_projects", values: updateValues, matching: filter)
    }

    public func listProjects(limit: Int, offset: Int) async throws -> [CodebaseProject] {
        let data = try await databaseClient.select(from: "codebase_projects", columns: nil, filter: nil)
        let records = try decode([SupabaseCodebaseProjectRecord].self, from: data)
        return Array(records.dropFirst(offset).prefix(limit))
            .map { mapper.projectToDomain($0) }
    }

    // MARK: - Internal Helpers

    internal func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        // Note: Don't use .convertFromSnakeCase - DTOs have explicit CodingKeys
        // Using both causes key conflicts (double conversion)
        return try decoder.decode(type, from: data)
    }
}

import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// PostgreSQL implementation of Codebase Repository
/// Single Responsibility: Codebase persistence via local PostgreSQL
/// Uses direct SQL queries via PostgreSQLDatabasePort
public final class PostgreSQLCodebaseRepository: CodebaseRepositoryPort {
    internal let databaseClient: PostgreSQLDatabasePort
    internal let mapper: PostgreSQLCodebaseMapper

    public init(databaseClient: PostgreSQLDatabasePort) {
        self.databaseClient = databaseClient
        self.mapper = PostgreSQLCodebaseMapper()
    }

    // MARK: - Codebase Operations

    public func createCodebase(_ codebase: Codebase) async throws -> Codebase {
        let dict = mapper.codebaseToDict(codebase)
        let data = try await databaseClient.upsert(
            table: "codebases",
            values: dict,
            onConflict: ["user_id", "repository_url"]
        )
        let rows = try decodeRows(from: data)
        guard let row = rows.first else {
            throw PostgreSQLError.invalidResultFormat
        }
        return try mapper.codebaseToDomain(row)
    }

    public func getCodebase(by id: UUID) async throws -> Codebase? {
        let data = try await databaseClient.select(
            from: "codebases",
            columns: nil,
            whereClause: "id = $1",
            parameters: [id.uuidString]
        )
        let rows = try decodeRows(from: data)
        return try rows.first.map { try mapper.codebaseToDomain($0) }
    }

    public func listCodebases(forUser userId: UUID) async throws -> [Codebase] {
        let data = try await databaseClient.select(
            from: "codebases",
            columns: nil,
            whereClause: "user_id = $1",
            parameters: [userId.uuidString]
        )
        let rows = try decodeRows(from: data)
        return try rows.map { try mapper.codebaseToDomain($0) }
    }

    public func updateCodebase(_ codebase: Codebase) async throws -> Codebase {
        let dict = mapper.codebaseToDict(codebase)
        let data = try await databaseClient.update(
            table: "codebases",
            values: dict,
            whereClause: "id = $1",
            parameters: [codebase.id.uuidString]
        )
        let rows = try decodeRows(from: data)
        guard let row = rows.first else {
            throw PostgreSQLError.invalidResultFormat
        }
        return try mapper.codebaseToDomain(row)
    }

    public func deleteCodebase(_ id: UUID) async throws {
        try await databaseClient.delete(
            from: "codebases",
            whereClause: "id = $1",
            parameters: [id.uuidString]
        )
    }

    // MARK: - Codebase Project Operations

    public func saveProject(_ project: CodebaseProject) async throws -> CodebaseProject {
        let dict = mapper.projectToDict(project)
        let data = try await databaseClient.insert(table: "codebase_projects", values: dict)
        let rows = try decodeRows(from: data)
        guard let row = rows.first else {
            throw PostgreSQLError.invalidResultFormat
        }
        return try mapper.projectToDomain(row)
    }

    public func findProjectById(_ id: UUID) async throws -> CodebaseProject? {
        let data = try await databaseClient.select(
            from: "codebase_projects",
            columns: nil,
            whereClause: "id = $1",
            parameters: [id.uuidString]
        )
        let rows = try decodeRows(from: data)
        return try rows.first.map { try mapper.projectToDomain($0) }
    }

    public func findProjectByRepository(url: String, branch: String) async throws -> CodebaseProject? {
        let data = try await databaseClient.select(
            from: "codebase_projects",
            columns: nil,
            whereClause: "repository_url = $1 AND branch = $2",
            parameters: [url, branch]
        )
        let rows = try decodeRows(from: data)
        return try rows.first.map { try mapper.projectToDomain($0) }
    }

    public func updateProject(_ project: CodebaseProject) async throws -> CodebaseProject {
        let dict = mapper.projectToDict(project)
        let data = try await databaseClient.update(
            table: "codebase_projects",
            values: dict,
            whereClause: "id = $1",
            parameters: [project.id.uuidString]
        )
        let rows = try decodeRows(from: data)
        guard let row = rows.first else {
            throw PostgreSQLError.invalidResultFormat
        }
        return try mapper.projectToDomain(row)
    }

    public func deleteProject(_ id: UUID) async throws {
        try await databaseClient.delete(
            from: "codebase_projects",
            whereClause: "id = $1",
            parameters: [id.uuidString]
        )
    }

    public func updateProjectIndexingError(projectId: UUID, error: String) async throws {
        let updateDict: [String: Any] = [
            "indexing_status": "failed",
            "indexing_error": error,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        _ = try await databaseClient.update(
            table: "codebase_projects",
            values: updateDict,
            whereClause: "id = $1",
            parameters: [projectId.uuidString]
        )
    }

    public func listProjects(limit: Int, offset: Int) async throws -> [CodebaseProject] {
        let sql = """
        SELECT * FROM codebase_projects
        ORDER BY created_at DESC
        LIMIT $1 OFFSET $2;
        """
        let rows = try await databaseClient.executeQuery(sql, parameters: [limit, offset])
        return try rows.map { try mapper.projectToDomain($0) }
    }

    // MARK: - Internal Helpers

    internal func decodeRows(from data: Data) throws -> [[String: Any]] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw PostgreSQLError.invalidResultFormat
        }
        return json
    }
}

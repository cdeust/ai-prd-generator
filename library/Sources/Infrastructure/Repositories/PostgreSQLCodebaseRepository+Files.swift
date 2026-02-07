import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Extension for file operations
/// Single Responsibility: Code file persistence
extension PostgreSQLCodebaseRepository {
    // MARK: - Code File Operations

    public func saveFiles(_ files: [CodeFile], projectId: UUID) async throws -> [CodeFile] {
        let dicts = files.map { mapper.fileToDict($0) }
        let data = try await databaseClient.insertBatch(table: "code_files", values: dicts)
        let rows = try decodeRows(from: data)
        return try rows.map { try mapper.fileToDomain($0) }
    }

    public func addFile(_ file: CodeFile) async throws -> CodeFile {
        let dict = mapper.fileToDict(file)
        let data = try await databaseClient.insert(table: "code_files", values: dict)
        let rows = try decodeRows(from: data)
        guard let row = rows.first else {
            throw PostgreSQLError.invalidResultFormat
        }
        return try mapper.fileToDomain(row)
    }

    public func findFilesByProject(_ projectId: UUID) async throws -> [CodeFile] {
        let data = try await databaseClient.select(
            from: "code_files",
            columns: nil,
            whereClause: "project_id = $1",
            parameters: [projectId.uuidString]
        )
        let rows = try decodeRows(from: data)
        return try rows.map { try mapper.fileToDomain($0) }
    }

    public func findFile(projectId: UUID, path: String) async throws -> CodeFile? {
        let data = try await databaseClient.select(
            from: "code_files",
            columns: nil,
            whereClause: "project_id = $1 AND file_path = $2",
            parameters: [projectId.uuidString, path]
        )
        let rows = try decodeRows(from: data)
        return try rows.first.map { try mapper.fileToDomain($0) }
    }

    public func updateFileParsed(fileId: UUID, isParsed: Bool, error: String?) async throws {
        var updateDict: [String: Any] = [
            "is_parsed": isParsed,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        if let error = error {
            updateDict["parse_error"] = error
        }
        _ = try await databaseClient.update(
            table: "code_files",
            values: updateDict,
            whereClause: "id = $1",
            parameters: [fileId.uuidString]
        )
    }
}

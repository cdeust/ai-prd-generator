import Foundation
import Domain

/// Extension for file operations
/// Single Responsibility: Code file persistence
extension SupabaseCodebaseRepository {
    // MARK: - Code File Operations

    public func saveFiles(_ files: [CodeFile], projectId: UUID) async throws -> [CodeFile] {
        let records = files.map { mapper.fileToRecord($0) }
        let data = try await databaseClient.insertBatch(table: "code_files", values: records)
        let savedRecords = try decode([SupabaseCodeFileRecord].self, from: data)
        return savedRecords.map { mapper.fileToDomain($0) }
    }

    public func addFile(_ file: CodeFile) async throws -> CodeFile {
        let record = mapper.fileToRecord(file)
        let data = try await databaseClient.insert(table: "code_files", values: record)
        let savedRecord = try decode([SupabaseCodeFileRecord].self, from: data).first!
        return mapper.fileToDomain(savedRecord)
    }

    public func findFilesByProject(_ projectId: UUID) async throws -> [CodeFile] {
        let filter = QueryFilter(field: "codebase_id", operation: .equals, value: projectId.uuidString)
        let data = try await databaseClient.select(from: "code_files", columns: nil, filter: filter)
        let records = try decode([SupabaseCodeFileRecord].self, from: data)
        return records.map { mapper.fileToDomain($0) }
    }

    public func findFile(projectId: UUID, path: String) async throws -> CodeFile? {
        let filter = QueryFilter(field: "codebase_id", operation: .equals, value: projectId.uuidString)
        let data = try await databaseClient.select(from: "code_files", columns: nil, filter: filter)
        let records = try decode([SupabaseCodeFileRecord].self, from: data)
        return records
            .first { $0.filePath == path }
            .map { mapper.fileToDomain($0) }
    }

    public func updateFileParsed(fileId: UUID, isParsed: Bool, error: String?) async throws {
        let updateData = FileParseUpdate(
            isParsed: isParsed,
            parseError: error,
            updatedAt: Date()
        )
        let filter = QueryFilter(field: "id", operation: .equals, value: fileId.uuidString)
        _ = try await databaseClient.update(
            table: "code_files",
            values: updateData,
            matching: filter
        )
    }
}

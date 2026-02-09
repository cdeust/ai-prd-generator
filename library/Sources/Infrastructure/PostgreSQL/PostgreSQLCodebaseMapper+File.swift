import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Extension for CodeFile mapping
/// Single Responsibility: Map CodeFile between database and domain
extension PostgreSQLCodebaseMapper {
    // MARK: - CodeFile Mapping

    public func fileToDomain(_ row: [String: Any]) throws -> CodeFile {
        guard let id = row["id"] as? String,
              let codebaseId = row["codebase_id"] as? String,
              let projectId = row["project_id"] as? String,
              let filePath = row["file_path"] as? String,
              let fileHash = row["file_hash"] as? String,
              let fileSize = row["file_size"] as? Int,
              let isParsed = row["is_parsed"] as? Bool,
              let createdAt = row["created_at"] as? String else {
            throw PostgreSQLError.missingRequiredColumn("file mapping")
        }

        return CodeFile(
            id: UUID(uuidString: id) ?? UUID(),
            codebaseId: UUID(uuidString: codebaseId) ?? UUID(),
            projectId: UUID(uuidString: projectId) ?? UUID(),
            filePath: filePath,
            fileHash: fileHash,
            fileSize: fileSize,
            language: (row["language"] as? String).flatMap { ProgrammingLanguage(rawValue: $0) },
            isParsed: isParsed,
            parseError: row["parse_error"] as? String,
            createdAt: parseISO8601Date(createdAt) ?? Date()
        )
    }

    public func fileToDict(_ domain: CodeFile) -> [String: Any] {
        var dict: [String: Any] = [
            "id": domain.id.uuidString,
            "codebase_id": domain.codebaseId.uuidString,
            "project_id": domain.projectId.uuidString,
            "file_path": domain.filePath,
            "file_hash": domain.fileHash,
            "file_size": domain.fileSize,
            "is_parsed": domain.isParsed,
            "created_at": formatISO8601Date(domain.createdAt)
        ]

        if let language = domain.language {
            dict["language"] = language.rawValue
        }

        if let parseError = domain.parseError {
            dict["parse_error"] = parseError
        }

        return dict
    }
}

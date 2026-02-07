import AIPRDSharedUtilities
import Foundation

/// DTO for file-level full-text search results
/// Maps database file search response to domain CodeFile
struct FileFullTextSearchResultDTO: Codable, Sendable {
    let fileId: String
    let codebaseId: String
    let projectId: String
    let filePath: String
    let fileHash: String
    let fileSize: Int
    let language: String?
    let isParsed: Bool
    let parseError: String?
    let createdAt: String
    let updatedAt: String
    let bm25Score: Float

    enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case codebaseId = "codebase_id"
        case projectId = "project_id"
        case filePath = "file_path"
        case fileHash = "file_hash"
        case fileSize = "file_size"
        case language
        case isParsed = "is_parsed"
        case parseError = "parse_error"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case bm25Score = "bm25_score"
    }

    func toFileTuple() throws -> (file: CodeFile, bm25Score: Float) {
        guard let fileUUID = UUID(uuidString: fileId),
              let codebaseUUID = UUID(uuidString: codebaseId),
              let projectUUID = UUID(uuidString: projectId) else {
            throw FileMappingError.invalidUUID
        }

        var lang: ProgrammingLanguage?
        if let languageStr = language {
            guard let parsedLang = ProgrammingLanguage(rawValue: languageStr) else {
                throw FileMappingError.invalidLanguage(languageStr)
            }
            lang = parsedLang
        }

        // Parse ISO8601 timestamps
        let formatter = ISO8601DateFormatter()
        let created = formatter.date(from: createdAt) ?? Date()
        let updated = formatter.date(from: updatedAt) ?? Date()

        let file = CodeFile(
            id: fileUUID,
            codebaseId: codebaseUUID,
            projectId: projectUUID,
            filePath: filePath,
            fileHash: fileHash,
            fileSize: fileSize,
            language: lang,
            isParsed: isParsed,
            parseError: parseError,
            createdAt: created,
            updatedAt: updated
        )

        return (file, bm25Score)
    }
}

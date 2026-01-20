import Foundation

/// Supabase Code File Record
/// Maps to code_files table schema (000_complete_schema.sql)
/// Backend compatibility layer (ONLY exception per Rule 8)
public struct SupabaseCodeFileRecord: Codable, Sendable {
    let id: String
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

    enum CodingKeys: String, CodingKey {
        case id
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
    }

    /// Initializer for creating records to insert
    public init(
        id: String,
        codebaseId: String,
        projectId: String,
        filePath: String,
        fileHash: String,
        fileSize: Int,
        language: String?,
        isParsed: Bool,
        parseError: String?,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.codebaseId = codebaseId
        self.projectId = projectId
        self.filePath = filePath
        self.fileHash = fileHash
        self.fileSize = fileSize
        self.language = language
        self.isParsed = isParsed
        self.parseError = parseError
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Custom encode to ensure all keys are present (PostgREST requires consistent keys in batch inserts)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(codebaseId, forKey: .codebaseId)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(filePath, forKey: .filePath)
        try container.encode(fileHash, forKey: .fileHash)
        try container.encode(fileSize, forKey: .fileSize)
        try container.encode(language, forKey: .language)  // Encodes null if nil
        try container.encode(isParsed, forKey: .isParsed)
        try container.encode(parseError, forKey: .parseError)  // Encodes null if nil
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

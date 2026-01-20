import Foundation

/// Supabase Codebase Record
/// Maps to codebases table schema (000_complete_schema.sql)
/// Backend compatibility layer (ONLY exception per Rule 8)
public struct SupabaseCodebaseRecord: Codable, Sendable {
    let id: String
    let userId: String
    let name: String
    let description: String?
    let repositoryUrl: String?
    let localPath: String?
    let repositoryType: String?
    let defaultBranch: String?
    let indexingStatus: String
    let totalFiles: Int
    let indexedFiles: Int
    let detectedLanguages: [String]
    let lastIndexedAt: String?
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case description
        case repositoryUrl = "repository_url"
        case localPath = "local_path"
        case repositoryType = "repository_type"
        case defaultBranch = "default_branch"
        case indexingStatus = "indexing_status"
        case totalFiles = "total_files"
        case indexedFiles = "indexed_files"
        case detectedLanguages = "detected_languages"
        case lastIndexedAt = "last_indexed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        repositoryUrl = try container.decodeIfPresent(String.self, forKey: .repositoryUrl)
        localPath = try container.decodeIfPresent(String.self, forKey: .localPath)
        repositoryType = try container.decodeIfPresent(String.self, forKey: .repositoryType)
        defaultBranch = try container.decodeIfPresent(String.self, forKey: .defaultBranch)
        indexingStatus = try container.decode(String.self, forKey: .indexingStatus)
        totalFiles = try container.decode(Int.self, forKey: .totalFiles)
        indexedFiles = try container.decode(Int.self, forKey: .indexedFiles)
        lastIndexedAt = try container.decodeIfPresent(String.self, forKey: .lastIndexedAt)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)

        // Handle both JSON string and array for detected_languages
        if let jsonString = try? container.decode(String.self, forKey: .detectedLanguages) {
            if let data = jsonString.data(using: .utf8),
               let array = try? JSONDecoder().decode([String].self, from: data) {
                detectedLanguages = array
            } else {
                detectedLanguages = []
            }
        } else if let array = try? container.decode([String].self, forKey: .detectedLanguages) {
            detectedLanguages = array
        } else {
            detectedLanguages = []
        }
    }

    /// Initializer for creating records to insert
    public init(
        id: String,
        userId: String,
        name: String,
        description: String? = nil,
        repositoryUrl: String?,
        localPath: String?,
        repositoryType: String? = "git",
        defaultBranch: String? = "main",
        indexingStatus: String,
        totalFiles: Int,
        indexedFiles: Int,
        detectedLanguages: [String],
        lastIndexedAt: String? = nil,
        createdAt: String,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.repositoryUrl = repositoryUrl
        self.localPath = localPath
        self.repositoryType = repositoryType
        self.defaultBranch = defaultBranch
        self.indexingStatus = indexingStatus
        self.totalFiles = totalFiles
        self.indexedFiles = indexedFiles
        self.detectedLanguages = detectedLanguages
        self.lastIndexedAt = lastIndexedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

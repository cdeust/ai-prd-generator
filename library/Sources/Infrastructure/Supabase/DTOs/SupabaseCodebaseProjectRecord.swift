import Foundation

/// Supabase Codebase Project Record
/// Maps to codebase_projects table schema (000_complete_schema.sql)
/// Backend compatibility layer (ONLY exception per Rule 8)
public struct SupabaseCodebaseProjectRecord: Codable, Sendable {
    let id: String
    let codebaseId: String
    let name: String
    let repositoryUrl: String
    let branch: String
    let commitSha: String?
    let indexingStatus: String
    let indexingStartedAt: String?
    let indexingCompletedAt: String?
    let indexingError: String?
    let totalFiles: Int
    let totalChunks: Int
    let totalTokens: Int
    let merkleRootHash: String?
    let detectedLanguages: [String]?
    let detectedFrameworks: [String]?
    let architecturePatterns: [ArchitecturePatternData]?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case codebaseId = "codebase_id"
        case name
        case repositoryUrl = "repository_url"
        case branch
        case commitSha = "commit_sha"
        case indexingStatus = "indexing_status"
        case indexingStartedAt = "indexing_started_at"
        case indexingCompletedAt = "indexing_completed_at"
        case indexingError = "indexing_error"
        case totalFiles = "total_files"
        case totalChunks = "total_chunks"
        case totalTokens = "total_tokens"
        case merkleRootHash = "merkle_root_hash"
        case detectedLanguages = "detected_languages"
        case detectedFrameworks = "detected_frameworks"
        case architecturePatterns = "architecture_patterns"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        codebaseId = try container.decode(String.self, forKey: .codebaseId)
        name = try container.decode(String.self, forKey: .name)
        repositoryUrl = try container.decode(String.self, forKey: .repositoryUrl)
        branch = try container.decode(String.self, forKey: .branch)
        commitSha = try container.decodeIfPresent(String.self, forKey: .commitSha)
        indexingStatus = try container.decode(String.self, forKey: .indexingStatus)
        indexingStartedAt = try container.decodeIfPresent(String.self, forKey: .indexingStartedAt)
        indexingCompletedAt = try container.decodeIfPresent(String.self, forKey: .indexingCompletedAt)
        indexingError = try container.decodeIfPresent(String.self, forKey: .indexingError)
        totalFiles = try container.decode(Int.self, forKey: .totalFiles)
        totalChunks = try container.decode(Int.self, forKey: .totalChunks)
        totalTokens = try container.decode(Int.self, forKey: .totalTokens)
        merkleRootHash = try container.decodeIfPresent(String.self, forKey: .merkleRootHash)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)

        // Handle both JSON string and array for detected_languages
        detectedLanguages = Self.decodeStringArray(from: container, forKey: .detectedLanguages)

        // Handle both JSON string and array for detected_frameworks
        detectedFrameworks = Self.decodeStringArray(from: container, forKey: .detectedFrameworks)

        // Handle both JSON string and array for architecture_patterns
        if let jsonString = try? container.decode(String.self, forKey: .architecturePatterns) {
            if let data = jsonString.data(using: .utf8),
               let patterns = try? JSONDecoder().decode([ArchitecturePatternData].self, from: data) {
                architecturePatterns = patterns
            } else {
                architecturePatterns = nil
            }
        } else {
            architecturePatterns = try container.decodeIfPresent([ArchitecturePatternData].self, forKey: .architecturePatterns)
        }
    }

    private static func decodeStringArray(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> [String]? {
        if let jsonString = try? container.decode(String.self, forKey: key) {
            if let data = jsonString.data(using: .utf8),
               let array = try? JSONDecoder().decode([String].self, from: data) {
                return array
            }
            return nil
        }
        return try? container.decodeIfPresent([String].self, forKey: key)
    }

    /// Initializer for creating records to insert
    public init(
        id: String,
        codebaseId: String,
        name: String,
        repositoryUrl: String,
        branch: String,
        commitSha: String?,
        indexingStatus: String,
        indexingStartedAt: String?,
        indexingCompletedAt: String?,
        indexingError: String?,
        totalFiles: Int,
        totalChunks: Int,
        totalTokens: Int,
        merkleRootHash: String?,
        detectedLanguages: [String]?,
        detectedFrameworks: [String]?,
        architecturePatterns: [ArchitecturePatternData]?,
        createdAt: String,
        updatedAt: String
    ) {
        self.id = id
        self.codebaseId = codebaseId
        self.name = name
        self.repositoryUrl = repositoryUrl
        self.branch = branch
        self.commitSha = commitSha
        self.indexingStatus = indexingStatus
        self.indexingStartedAt = indexingStartedAt
        self.indexingCompletedAt = indexingCompletedAt
        self.indexingError = indexingError
        self.totalFiles = totalFiles
        self.totalChunks = totalChunks
        self.totalTokens = totalTokens
        self.merkleRootHash = merkleRootHash
        self.detectedLanguages = detectedLanguages
        self.detectedFrameworks = detectedFrameworks
        self.architecturePatterns = architecturePatterns
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

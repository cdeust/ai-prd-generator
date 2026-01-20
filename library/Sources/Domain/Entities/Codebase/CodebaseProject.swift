import Foundation

/// Codebase project with indexing metadata
/// Following Single Responsibility Principle - represents codebase project
public struct CodebaseProject: Identifiable, Sendable {
    public let id: UUID
    public let codebaseId: UUID
    public let name: String
    public let repositoryUrl: String
    public let branch: String
    public let commitSha: String?
    public let indexingStatus: IndexingStatus
    public let indexingStartedAt: Date?
    public let indexingCompletedAt: Date?
    public let indexingError: String?
    public let totalFiles: Int
    public let totalChunks: Int
    public let totalTokens: Int
    public let merkleRootHash: String?
    public let detectedLanguages: [String]
    public let detectedFrameworks: [String]
    public let architecturePatterns: [DetectedArchitecturePattern]
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        codebaseId: UUID,
        name: String,
        repositoryUrl: String,
        branch: String,
        commitSha: String? = nil,
        indexingStatus: IndexingStatus = .pending,
        indexingStartedAt: Date? = nil,
        indexingCompletedAt: Date? = nil,
        indexingError: String? = nil,
        totalFiles: Int = 0,
        totalChunks: Int = 0,
        totalTokens: Int = 0,
        merkleRootHash: String? = nil,
        detectedLanguages: [String] = [],
        detectedFrameworks: [String] = [],
        architecturePatterns: [DetectedArchitecturePattern] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
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

    public var isIndexingComplete: Bool {
        indexingStatus == .completed
    }

    public var isIndexingFailed: Bool {
        indexingStatus == .failed
    }
}

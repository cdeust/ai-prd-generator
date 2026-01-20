import Foundation

/// Entity representing an indexed codebase
/// Following Single Responsibility Principle - manages codebase metadata
public struct Codebase: Identifiable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let name: String
    public let repositoryUrl: String?
    public let localPath: String?
    public let indexingStatus: IndexingStatus
    public let totalFiles: Int
    public let indexedFiles: Int
    public let detectedLanguages: [String]
    public let createdAt: Date
    public let lastIndexedAt: Date?

    public init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        repositoryUrl: String? = nil,
        localPath: String? = nil,
        indexingStatus: IndexingStatus = .pending,
        totalFiles: Int = 0,
        indexedFiles: Int = 0,
        detectedLanguages: [String] = [],
        createdAt: Date = Date(),
        lastIndexedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.repositoryUrl = repositoryUrl
        self.localPath = localPath
        self.indexingStatus = indexingStatus
        self.totalFiles = totalFiles
        self.indexedFiles = indexedFiles
        self.detectedLanguages = detectedLanguages
        self.createdAt = createdAt
        self.lastIndexedAt = lastIndexedAt
    }

    public var indexingProgress: Double {
        calculateProgress()
    }

    public var isIndexingComplete: Bool {
        indexingStatus == .completed && indexedFiles == totalFiles
    }

    public func needsReindexing(afterDays days: Int = 7) -> Bool {
        checkReindexingNeeded(afterDays: days)
    }

    private func calculateProgress() -> Double {
        guard totalFiles > 0 else { return 0.0 }
        return Double(indexedFiles) / Double(totalFiles)
    }

    private func checkReindexingNeeded(afterDays days: Int) -> Bool {
        guard let lastIndexed = lastIndexedAt else { return true }
        let daysSinceIndexing = Calendar.current
            .dateComponents([.day], from: lastIndexed, to: Date()).day ?? 0
        return daysSinceIndexing >= days
    }
}

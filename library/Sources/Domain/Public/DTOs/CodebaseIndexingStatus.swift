import Foundation

/// Public codebase indexing status
/// Public DTO for indexing progress
public struct CodebaseIndexingStatus: Sendable {
    public let id: UUID
    public let status: String
    public let progress: Int
    public let totalFiles: Int
    public let indexedFiles: Int
    public let detectedLanguages: [String: Int]

    public init(
        id: UUID,
        status: String,
        progress: Int,
        totalFiles: Int,
        indexedFiles: Int,
        detectedLanguages: [String: Int]
    ) {
        self.id = id
        self.status = status
        self.progress = progress
        self.totalFiles = totalFiles
        self.indexedFiles = indexedFiles
        self.detectedLanguages = detectedLanguages
    }
}

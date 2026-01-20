import Foundation
import Domain

/// Codebase context for PRD generation
public struct CodebaseContext: Sendable {
    /// Codebase identifier
    public let codebaseId: UUID

    /// Project name
    public let projectName: String

    /// Repository type (git, local, etc.)
    public let repositoryType: RepositoryType

    /// Total number of indexed files
    public let totalFiles: Int

    /// Relevant code chunks
    public let relevantChunks: [CodeChunk]

    public init(
        codebaseId: UUID,
        projectName: String,
        repositoryType: RepositoryType,
        totalFiles: Int,
        relevantChunks: [CodeChunk]
    ) {
        self.codebaseId = codebaseId
        self.projectName = projectName
        self.repositoryType = repositoryType
        self.totalFiles = totalFiles
        self.relevantChunks = relevantChunks
    }

    /// Total lines of code in relevant chunks
    public var totalLines: Int {
        relevantChunks.reduce(0) { $0 + $1.content.split(separator: "\n").count }
    }

    /// Unique file paths in relevant chunks
    public var uniqueFiles: Set<String> {
        Set(relevantChunks.map { $0.filePath })
    }

    /// Check if context is substantial
    public var hasSubstantialContext: Bool {
        
        relevantChunks.count >= 10
    }
}

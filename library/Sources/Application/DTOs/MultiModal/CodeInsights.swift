import Foundation
import Domain

/// Code insights extracted from codebase analysis
public struct CodeInsights: Sendable, Equatable {
    /// Project name
    public let projectName: String

    /// Repository type
    public let repositoryType: RepositoryType

    /// Total files in codebase
    public let totalFiles: Int

    /// Relevant files analyzed
    public let relevantFilesCount: Int

    /// Total lines of code analyzed
    public let totalLines: Int

    /// Programming languages detected
    public let languages: Set<String>

    public init(
        projectName: String,
        repositoryType: RepositoryType,
        totalFiles: Int,
        relevantFilesCount: Int,
        totalLines: Int,
        languages: Set<String>
    ) {
        self.projectName = projectName
        self.repositoryType = repositoryType
        self.totalFiles = totalFiles
        self.relevantFilesCount = relevantFilesCount
        self.totalLines = totalLines
        self.languages = languages
    }

    /// Average lines per file
    public var averageLinesPerFile: Double {
        guard relevantFilesCount > 0 else { return 0.0 }
        return Double(totalLines) / Double(relevantFilesCount)
    }

    /// Check if codebase is substantial
    public var isSubstantial: Bool {
        totalFiles > 50 || totalLines > 1000
    }

    /// Primary language (most common)
    public var primaryLanguage: String? {
        languages.first
    }
}

import Foundation

/// Codebase context for gap detection
public struct CodebaseGapContext: Codable, Sendable {
    /// Number of indexed files
    public let fileCount: Int

    /// Primary programming languages
    public let languages: [String]

    /// Architecture patterns detected
    public let architecturePatterns: [String]

    /// Key technologies/frameworks found
    public let technologies: [String]

    public init(
        fileCount: Int,
        languages: [String],
        architecturePatterns: [String] = [],
        technologies: [String] = []
    ) {
        self.fileCount = fileCount
        self.languages = languages
        self.architecturePatterns = architecturePatterns
        self.technologies = technologies
    }
}

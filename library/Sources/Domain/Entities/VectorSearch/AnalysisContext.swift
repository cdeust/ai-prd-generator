import Foundation

/// Analysis context for codebase understanding
/// Following Single Responsibility Principle - represents analysis context
public struct AnalysisContext: Sendable {
    public let codebaseId: UUID
    public let relevantFiles: [CodeFile]
    public let relevantChunks: [CodeChunk]
    public let searchQuery: String?
    public let detectedPatterns: [String]

    public init(
        codebaseId: UUID,
        relevantFiles: [CodeFile] = [],
        relevantChunks: [CodeChunk] = [],
        searchQuery: String? = nil,
        detectedPatterns: [String] = []
    ) {
        self.codebaseId = codebaseId
        self.relevantFiles = relevantFiles
        self.relevantChunks = relevantChunks
        self.searchQuery = searchQuery
        self.detectedPatterns = detectedPatterns
    }
}

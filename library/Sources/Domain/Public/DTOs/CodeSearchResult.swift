import Foundation

/// Public code search result
/// Public DTO for search results
public struct CodeSearchResult: Sendable {
    public let filePath: String
    public let content: String
    public let similarity: Double
    public let startLine: Int
    public let endLine: Int

    public init(
        filePath: String,
        content: String,
        similarity: Double,
        startLine: Int,
        endLine: Int
    ) {
        self.filePath = filePath
        self.content = content
        self.similarity = similarity
        self.startLine = startLine
        self.endLine = endLine
    }
}

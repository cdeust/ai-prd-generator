import Foundation

/// A retrieved code chunk with its metadata
/// Captures what code was retrieved and its relevance
public struct RetrievedChunk: Sendable, Codable {
    public let chunkId: UUID
    public let filePath: String
    public let score: Double
    public let content: String
    public let startLine: Int?
    public let endLine: Int?
    public let metadata: [String: String]?

    public init(
        chunkId: UUID,
        filePath: String,
        score: Double,
        content: String,
        startLine: Int? = nil,
        endLine: Int? = nil,
        metadata: [String: String]? = nil
    ) {
        self.chunkId = chunkId
        self.filePath = filePath
        self.score = score
        self.content = content
        self.startLine = startLine
        self.endLine = endLine
        self.metadata = metadata
    }
}

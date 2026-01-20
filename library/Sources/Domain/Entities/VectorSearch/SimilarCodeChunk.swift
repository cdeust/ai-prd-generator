import Foundation

/// Similar code chunk (search result)
/// Following Single Responsibility Principle - represents similar chunk result
public struct SimilarCodeChunk: Identifiable, Sendable {
    public let id: UUID
    public let chunk: CodeChunk
    public let similarity: Double

    public init(
        id: UUID = UUID(),
        chunk: CodeChunk,
        similarity: Double
    ) {
        self.id = id
        self.chunk = chunk
        self.similarity = similarity
    }
}

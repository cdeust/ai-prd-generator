import Foundation

/// Vector search result with similarity score
/// Following Single Responsibility Principle - represents search result
public struct VectorSearchResult: Identifiable, Sendable {
    public let id: UUID
    public let chunk: CodeChunk
    public let file: CodeFile
    public let similarity: Float
    public let rank: Int

    public init(
        id: UUID = UUID(),
        chunk: CodeChunk,
        file: CodeFile,
        similarity: Float,
        rank: Int
    ) {
        self.id = id
        self.chunk = chunk
        self.file = file
        self.similarity = similarity
        self.rank = rank
    }
}

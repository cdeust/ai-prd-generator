import Foundation

/// Code embedding entity for vector storage
/// Following Single Responsibility Principle - represents code embedding
public struct CodeEmbedding: Identifiable, Sendable {
    public let id: UUID
    public let chunkId: UUID
    public let projectId: UUID
    public let embedding: [Float]
    public let model: String
    public let embeddingVersion: Int
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        chunkId: UUID,
        projectId: UUID,
        embedding: [Float],
        model: String,
        embeddingVersion: Int = 1,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.chunkId = chunkId
        self.projectId = projectId
        self.embedding = embedding
        self.model = model
        self.embeddingVersion = embeddingVersion
        self.createdAt = createdAt
    }

    /// Embedding dimension (vector length)
    public var dimension: Int {
        embedding.count
    }
}

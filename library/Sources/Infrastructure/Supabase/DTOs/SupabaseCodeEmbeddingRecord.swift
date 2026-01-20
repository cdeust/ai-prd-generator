import Foundation

/// Supabase Code Embedding Record
/// Maps to code_embeddings table schema (000_complete_schema.sql)
/// Backend compatibility layer (ONLY exception per Rule 8)
public struct SupabaseCodeEmbeddingRecord: Codable, Sendable {
    let id: String
    let chunkId: String
    let projectId: String
    let embedding: [Float]
    let model: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case chunkId = "chunk_id"
        case projectId = "project_id"
        case embedding
        case model
        case createdAt = "created_at"
    }

    /// Initializer for creating records to insert
    public init(
        id: String,
        chunkId: String,
        projectId: String,
        embedding: [Float],
        model: String,
        createdAt: String
    ) {
        self.id = id
        self.chunkId = chunkId
        self.projectId = projectId
        self.embedding = embedding
        self.model = model
        self.createdAt = createdAt
    }
}

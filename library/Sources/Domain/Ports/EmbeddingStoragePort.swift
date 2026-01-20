import Foundation

/// Port for storing and managing embeddings (Supabase)
/// Domain interface for embedding persistence
public protocol EmbeddingStoragePort: Sendable {
    /// Store embeddings for code chunks
    /// - Parameters:
    ///   - embeddings: Embeddings to store
    ///   - projectId: Associated project
    func storeEmbeddings(_ embeddings: [CodeEmbedding], projectId: UUID) async throws

    /// Get embeddings for specific chunks
    /// - Parameter chunkIds: Chunk IDs
    /// - Returns: Embeddings
    func getEmbeddings(for chunkIds: [UUID]) async throws -> [CodeEmbedding]

    /// Delete embeddings for project (for re-indexing)
    /// - Parameter projectId: Project ID
    func deleteEmbeddings(for projectId: UUID) async throws

    /// Get embedding by chunk ID
    /// - Parameter chunkId: Chunk ID
    /// - Returns: Embedding if exists
    func getEmbedding(for chunkId: UUID) async throws -> CodeEmbedding?

    /// Count embeddings for project
    /// - Parameter projectId: Project ID
    /// - Returns: Count of embeddings
    func countEmbeddings(for projectId: UUID) async throws -> Int
}

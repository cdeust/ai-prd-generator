import Foundation

/// Port for generating text embeddings
/// Domain defines the interface, Infrastructure implements it
public protocol EmbeddingGeneratorPort: Sendable {
    /// Generate embedding for a single text
    /// - Parameter text: Input text
    /// - Returns: Vector embedding
    func generateEmbedding(text: String) async throws -> [Float]

    /// Generate embeddings for multiple texts (batch operation)
    /// - Parameter texts: Array of input texts
    /// - Returns: Array of vector embeddings
    func generateEmbeddings(texts: [String]) async throws -> [[Float]]

    /// Generate embedding for code chunk
    func generateCodeEmbedding(chunk: CodeChunk) async throws -> CodeEmbedding

    /// Get the dimension size of embeddings
    var dimension: Int { get }

    /// Get the model name
    var modelName: String { get }

    /// The embedding version
    var embeddingVersion: Int { get }
}

import Foundation

/// Port for semantic, late, and hierarchical text chunking.
///
/// Chunking strategies:
/// - **Semantic**: Chunk by meaning boundaries (paragraphs, topics)
/// - **Late**: Chunk after embedding (Jina 2025 research)
/// - **Hierarchical**: Multi-level chunking (document → section → paragraph)
/// - **Fixed**: Traditional fixed-size chunks (baseline)
///
/// Used for:
/// - RAG system context preparation
/// - Token budget allocation
/// - Multi-model context optimization
/// - Code structure analysis
public protocol ChunkerPort: Sendable {
    /// Chunk text using semantic boundaries
    ///
    /// - Parameters:
    ///   - text: Text to chunk
    ///   - maxTokens: Maximum tokens per chunk
    ///   - strategy: Chunking strategy to use
    /// - Returns: Array of semantic chunks
    /// - Throws: ChunkingError if chunking fails
    func chunk(
        _ text: String,
        maxTokens: Int,
        strategy: ChunkingStrategy
    ) async throws -> [TextChunk]

    /// Chunk code respecting structure boundaries
    ///
    /// - Parameters:
    ///   - code: Code to chunk
    ///   - maxTokens: Maximum tokens per chunk
    ///   - language: Programming language
    /// - Returns: Array of code chunks
    /// - Throws: ChunkingError if chunking fails
    func chunkCode(
        _ code: String,
        maxTokens: Int,
        language: ProgrammingLanguage
    ) async throws -> [TextChunk]

    /// Chunk hierarchically (document → sections → paragraphs)
    ///
    /// - Parameters:
    ///   - text: Text to chunk
    ///   - levels: Number of hierarchy levels
    ///   - maxTokensPerLevel: Token limits per level
    /// - Returns: Hierarchical chunk tree
    /// - Throws: ChunkingError if chunking fails
    func chunkHierarchically(
        _ text: String,
        levels: Int,
        maxTokensPerLevel: [Int]
    ) async throws -> HierarchicalChunk
}

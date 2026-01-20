import Foundation

/// Semantic chunk with token-aware metadata
///
/// Supports both character-based and token-based indexing for flexibility.
/// Token-based indices are preferred for modern RAG systems.
public struct TextChunk: Sendable, Codable {
    public let id: UUID

    /// Chunk content
    public let content: String

    /// Token count (accurate from tokenizer)
    public let tokenCount: Int

    /// Character-based position in source (optional)
    public let characterRange: Range<Int>?

    /// Token-based position in source (optional, preferred)
    public let tokenRange: Range<Int>?

    /// Chunk metadata (strategy, language, semantic info)
    public let metadata: ChunkMetadata

    public init(
        id: UUID = UUID(),
        content: String,
        tokenCount: Int,
        characterRange: Range<Int>? = nil,
        tokenRange: Range<Int>? = nil,
        metadata: ChunkMetadata
    ) {
        self.id = id
        self.content = content
        self.tokenCount = tokenCount
        self.characterRange = characterRange
        self.tokenRange = tokenRange
        self.metadata = metadata
    }

    /// Legacy initializer for character-based indexing (backward compatible)
    public init(
        id: UUID = UUID(),
        content: String,
        tokenCount: Int,
        startIndex: Int,
        endIndex: Int,
        metadata: ChunkMetadata
    ) {
        self.id = id
        self.content = content
        self.tokenCount = tokenCount
        self.characterRange = startIndex..<endIndex
        self.tokenRange = nil
        self.metadata = metadata
    }
}

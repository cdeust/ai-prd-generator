import Foundation

/// Chunk metadata
public struct ChunkMetadata: Sendable, Codable {
    public let strategy: ChunkingStrategy
    public let language: ProgrammingLanguage?
    public let semanticLevel: Int?
    public let topic: String?

    public init(
        strategy: ChunkingStrategy,
        language: ProgrammingLanguage? = nil,
        semanticLevel: Int? = nil,
        topic: String? = nil
    ) {
        self.strategy = strategy
        self.language = language
        self.semanticLevel = semanticLevel
        self.topic = topic
    }
}

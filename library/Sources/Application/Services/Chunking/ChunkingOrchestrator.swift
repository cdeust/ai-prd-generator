import Foundation
import Domain

/// Orchestrates chunking strategy selection based on content type.
///
/// Selects optimal chunking strategy:
/// - **Semantic**: Natural text (documentation, user stories)
/// - **Hierarchical**: Structured documents (specs, architecture)
/// - **Code Structure**: Source code files
/// - **Late**: RAG embeddings (when available)
public struct ChunkingOrchestrator: Sendable {
    private let semanticChunker: ChunkerPort
    private let hierarchicalChunker: ChunkerPort
    private let codeChunker: ChunkerPort
    private let lateChunker: ChunkerPort?

    public init(
        semanticChunker: ChunkerPort,
        hierarchicalChunker: ChunkerPort,
        codeChunker: ChunkerPort,
        lateChunker: ChunkerPort? = nil
    ) {
        self.semanticChunker = semanticChunker
        self.hierarchicalChunker = hierarchicalChunker
        self.codeChunker = codeChunker
        self.lateChunker = lateChunker
    }

    /// Chunk content using optimal strategy
    public func chunk(
        _ content: String,
        maxTokens: Int,
        contentType: ContentType
    ) async throws -> [TextChunk] {
        let chunker = selectChunker(for: contentType)
        let strategy = selectStrategy(for: contentType)

        return try await chunker.chunk(content, maxTokens: maxTokens, strategy: strategy)
    }

    /// Chunk code with language-specific structure
    public func chunkCode(
        _ code: String,
        maxTokens: Int,
        language: ProgrammingLanguage
    ) async throws -> [TextChunk] {
        try await codeChunker.chunkCode(code, maxTokens: maxTokens, language: language)
    }

    /// Chunk hierarchically for structured documents
    public func chunkHierarchically(
        _ content: String,
        levels: Int,
        maxTokensPerLevel: [Int]
    ) async throws -> HierarchicalChunk {
        try await hierarchicalChunker.chunkHierarchically(
            content,
            levels: levels,
            maxTokensPerLevel: maxTokensPerLevel
        )
    }

    private func selectChunker(for contentType: ContentType) -> ChunkerPort {
        switch contentType {
        case .naturalText:
            return semanticChunker

        case .structuredDocument:
            return hierarchicalChunker

        case .sourceCode:
            return codeChunker

        case .embedding:
            return lateChunker ?? semanticChunker
        }
    }

    private func selectStrategy(for contentType: ContentType) -> ChunkingStrategy {
        switch contentType {
        case .naturalText:
            return .semantic

        case .structuredDocument:
            return .hierarchical

        case .sourceCode:
            return .semantic

        case .embedding:
            return .late
        }
    }
}

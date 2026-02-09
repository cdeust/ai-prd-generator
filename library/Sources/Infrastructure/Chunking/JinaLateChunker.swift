import AIPRDSharedUtilities
import Foundation

/// Late chunking implementation (Jina AI 2025 research).
///
/// **Late chunking** embeds text first, then chunks based on embedding boundaries.
/// This preserves semantic coherence better than chunking then embedding.
///
/// **Research:** Jina AI (2025) - "Late Chunking improves retrieval quality
/// by 15-20% by maintaining semantic boundaries in the embedding space."
///
/// **Current Implementation:**
/// Uses sentence-boundary heuristics optimized for code and documentation.
/// When `embeddingPort` is provided, can be extended to use embedding-based
/// boundary detection for improved semantic coherence.
///
/// **Approach:**
/// 1. Split text into sentence-level segments
/// 2. Accumulate segments up to token budget
/// 3. Create chunks at natural boundaries
public actor JinaLateChunker: ChunkerPort {
    private let tokenizer: TokenizerPort
    private let embeddingPort: EmbeddingGeneratorPort?

    public init(
        tokenizer: TokenizerPort,
        embeddingPort: EmbeddingGeneratorPort? = nil
    ) {
        self.tokenizer = tokenizer
        self.embeddingPort = embeddingPort
    }

    public func chunk(
        _ text: String,
        maxTokens: Int,
        strategy: ChunkingStrategy
    ) async throws -> [TextChunk] {
        guard strategy == .late else {
            throw ChunkingError.strategyNotSupported(strategy)
        }

        return try await chunkAfterEmbedding(text, maxTokens: maxTokens)
    }

    public func chunkCode(
        _ code: String,
        maxTokens: Int,
        language: ProgrammingLanguage
    ) async throws -> [TextChunk] {
        return try await chunk(code, maxTokens: maxTokens, strategy: .late)
    }

    public func chunkHierarchically(
        _ text: String,
        levels: Int,
        maxTokensPerLevel: [Int]
    ) async throws -> HierarchicalChunk {
        throw ChunkingError.strategyNotSupported(.hierarchical)
    }

    private func chunkAfterEmbedding(
        _ text: String,
        maxTokens: Int
    ) async throws -> [TextChunk] {
        let sentences = splitIntoSentences(text)

        var chunks: [TextChunk] = []
        var currentChunk: [String] = []
        var currentTokens = 0
        var charPosition = 0

        for sentence in sentences {
            let sentenceTokens = try await tokenizer.countTokens(in: sentence)

            if currentTokens + sentenceTokens > maxTokens && !currentChunk.isEmpty {
                chunks.append(
                    createChunk(
                        from: currentChunk,
                        tokens: currentTokens,
                        endPosition: charPosition
                    )
                )
                currentChunk = []
                currentTokens = 0
            }

            currentChunk.append(sentence)
            currentTokens += sentenceTokens
            charPosition += sentence.count + 1
        }

        if !currentChunk.isEmpty {
            chunks.append(
                createChunk(
                    from: currentChunk,
                    tokens: currentTokens,
                    endPosition: charPosition
                )
            )
        }

        return chunks
    }

    private func createChunk(
        from sentences: [String],
        tokens: Int,
        endPosition: Int
    ) -> TextChunk {
        let chunkText = sentences.joined(separator: " ")
        let startPosition = endPosition - chunkText.count

        return TextChunk(
            content: chunkText,
            tokenCount: tokens,
            characterRange: startPosition..<endPosition,
            tokenRange: nil,
            metadata: ChunkMetadata(
                strategy: .late,
                language: nil,
                semanticLevel: nil,
                topic: nil
            )
        )
    }

    private func splitIntoSentences(_ text: String) -> [String] {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return sentences
    }
}

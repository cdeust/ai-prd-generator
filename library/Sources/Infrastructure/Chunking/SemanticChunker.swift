import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Semantic chunker that splits text by paragraph and topic boundaries
public actor SemanticChunker: ChunkerPort {
    private let tokenizer: TokenizerPort

    public init(tokenizer: TokenizerPort) {
        self.tokenizer = tokenizer
    }

    public func chunk(
        _ text: String,
        maxTokens: Int,
        strategy: ChunkingStrategy
    ) async throws -> [TextChunk] {
        guard case .semantic = strategy else {
            throw ChunkingError.strategyNotSupported(strategy)
        }

        let paragraphs = extractParagraphs(from: text)
        var state = ChunkingState()

        for paragraph in paragraphs {
            state = try await processParagraph(
                paragraph,
                maxTokens: maxTokens,
                state: state,
                strategy: strategy
            )
        }

        if !state.currentChunk.isEmpty {
            let chunk = try await createChunk(
                content: state.currentChunk,
                start: state.currentStart,
                strategy: strategy
            )
            state = state.withChunk(chunk)
        }

        return state.chunks
    }

    public func chunkCode(
        _ code: String,
        maxTokens: Int,
        language: ProgrammingLanguage
    ) async throws -> [TextChunk] {
        try await chunk(code, maxTokens: maxTokens, strategy: .semantic)
    }

    public func chunkHierarchically(
        _ text: String,
        levels: Int,
        maxTokensPerLevel: [Int]
    ) async throws -> HierarchicalChunk {
        throw ChunkingError.strategyNotSupported(.hierarchical)
    }

    private func processParagraph(
        _ paragraph: String,
        maxTokens: Int,
        state: ChunkingState,
        strategy: ChunkingStrategy
    ) async throws -> ChunkingState {
        let paragraphTokens = try await tokenizer.countTokens(in: paragraph)

        if paragraphTokens > maxTokens {
            var newState = state
            if !state.currentChunk.isEmpty {
                let chunk = try await createChunk(
                    content: state.currentChunk,
                    start: state.currentStart,
                    strategy: strategy
                )
                newState = state.withChunk(chunk).withCurrentChunk("", start: 0)
            }

            let splitChunks = try await splitLargeParagraph(
                paragraph,
                maxTokens: maxTokens,
                strategy: strategy
            )

            for chunk in splitChunks {
                newState = newState.withChunk(chunk)
            }
            newState = newState.withCurrentChunk("", start: paragraph.count)
            return newState
        } else {
            return try await appendOrFlush(
                paragraph,
                maxTokens: maxTokens,
                state: state,
                strategy: strategy
            )
        }
    }

    private func appendOrFlush(
        _ paragraph: String,
        maxTokens: Int,
        state: ChunkingState,
        strategy: ChunkingStrategy
    ) async throws -> ChunkingState {
        let combinedTokens = try await tokenizer.countTokens(
            in: state.currentChunk + "\n\n" + paragraph
        )

        if combinedTokens <= maxTokens {
            return state.withAppendedChunk(paragraph)
        } else {
            let chunk = try await createChunk(
                content: state.currentChunk,
                start: state.currentStart,
                strategy: strategy
            )
            return state
                .withChunk(chunk)
                .withCurrentChunk(paragraph, start: state.currentStart + state.currentChunk.count)
        }
    }

    private func extractParagraphs(from text: String) -> [String] {
        text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func splitLargeParagraph(
        _ paragraph: String,
        maxTokens: Int,
        strategy: ChunkingStrategy
    ) async throws -> [TextChunk] {
        let sentences = extractSentences(from: paragraph)
        var chunks: [TextChunk] = []
        var currentChunk = ""
        var currentStart = 0

        for sentence in sentences {
            let combinedTokens = try await tokenizer.countTokens(
                in: currentChunk + " " + sentence
            )

            if combinedTokens > maxTokens && !currentChunk.isEmpty {
                let chunk = try await createChunk(
                    content: currentChunk,
                    start: currentStart,
                    strategy: strategy
                )
                chunks.append(chunk)
                currentChunk = sentence
                currentStart += currentChunk.count
            } else {
                if !currentChunk.isEmpty {
                    currentChunk += " "
                }
                currentChunk += sentence
            }
        }

        if !currentChunk.isEmpty {
            let chunk = try await createChunk(
                content: currentChunk,
                start: currentStart,
                strategy: strategy
            )
            chunks.append(chunk)
        }

        return chunks
    }

    private func extractSentences(from text: String) -> [String] {
        text.components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func createChunk(
        content: String,
        start: Int,
        strategy: ChunkingStrategy
    ) async throws -> TextChunk {
        let tokenCount = try await tokenizer.countTokens(in: content)
        return TextChunk(
            content: content,
            tokenCount: tokenCount,
            startIndex: start,
            endIndex: start + content.count,
            metadata: ChunkMetadata(
                strategy: strategy,
                semanticLevel: 0
            )
        )
    }
}

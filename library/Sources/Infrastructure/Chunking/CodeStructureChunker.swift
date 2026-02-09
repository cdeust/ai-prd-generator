import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

public actor CodeStructureChunker: ChunkerPort {
    private let tokenizer: TokenizerPort

    public init(tokenizer: TokenizerPort) {
        self.tokenizer = tokenizer
    }

    public func chunk(
        _ text: String,
        maxTokens: Int,
        strategy: ChunkingStrategy
    ) async throws -> [TextChunk] {
        throw ChunkingError.strategyNotSupported(strategy)
    }

    public func chunkCode(
        _ code: String,
        maxTokens: Int,
        language: ProgrammingLanguage
    ) async throws -> [TextChunk] {
        let declarations = extractDeclarations(from: code, language: language)
        var state = CodeChunkingState()

        for declaration in declarations {
            state = try await processDeclaration(
                declaration,
                maxTokens: maxTokens,
                state: state,
                language: language
            )
        }

        if !state.currentChunk.isEmpty {
            let chunk = try await createChunk(
                content: state.currentChunk,
                start: state.currentStart,
                language: language
            )
            state = state.withChunk(chunk)
        }

        return state.chunks
    }

    public func chunkHierarchically(
        _ text: String,
        levels: Int,
        maxTokensPerLevel: [Int]
    ) async throws -> HierarchicalChunk {
        throw ChunkingError.strategyNotSupported(.hierarchical)
    }

    private func processDeclaration(
        _ declaration: String,
        maxTokens: Int,
        state: CodeChunkingState,
        language: ProgrammingLanguage
    ) async throws -> CodeChunkingState {
        let declarationTokens = try await tokenizer.countTokens(in: declaration)

        if declarationTokens > maxTokens {
            var newState = state
            if !state.currentChunk.isEmpty {
                let chunk = try await createChunk(
                    content: state.currentChunk,
                    start: state.currentStart,
                    language: language
                )
                newState = state.withChunk(chunk).withCurrentChunk("", start: 0)
            }

            let splitChunks = try await splitLargeDeclaration(
                declaration,
                maxTokens: maxTokens,
                language: language
            )

            for chunk in splitChunks {
                newState = newState.withChunk(chunk)
            }
            newState = newState.withCurrentChunk("", start: declaration.count)
            return newState
        } else {
            return try await appendOrFlushDeclaration(
                declaration,
                maxTokens: maxTokens,
                state: state,
                language: language
            )
        }
    }

    private func appendOrFlushDeclaration(
        _ declaration: String,
        maxTokens: Int,
        state: CodeChunkingState,
        language: ProgrammingLanguage
    ) async throws -> CodeChunkingState {
        let combinedTokens = try await tokenizer.countTokens(
            in: state.currentChunk + "\n\n" + declaration
        )

        if combinedTokens <= maxTokens {
            return state.withAppendedChunk(declaration)
        } else {
            let chunk = try await createChunk(
                content: state.currentChunk,
                start: state.currentStart,
                language: language
            )
            return state
                .withChunk(chunk)
                .withCurrentChunk(declaration, start: state.currentStart + state.currentChunk.count)
        }
    }

    private func extractDeclarations(
        from code: String,
        language: ProgrammingLanguage
    ) -> [String] {
        switch language {
        case .swift:
            return extractSwiftDeclarations(from: code)
        case .python:
            return extractPythonDeclarations(from: code)
        case .typescript, .javascript:
            return extractJSDeclarations(from: code)
        case .go:
            return extractGoDeclarations(from: code)
        case .rust:
            return extractRustDeclarations(from: code)
        case .objectiveC, .kotlin, .java:
            return code.components(separatedBy: "\n\n").filter { !$0.isEmpty }
        case .unknown:
            return []
        }
    }

    private func extractSwiftDeclarations(from code: String) -> [String] {
        var declarations: [String] = []
        var currentDeclaration = ""
        var braceDepth = 0

        for line in code.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if isSwiftDeclarationStart(trimmed) && braceDepth == 0 {
                if !currentDeclaration.isEmpty {
                    declarations.append(currentDeclaration)
                }
                currentDeclaration = line + "\n"
            } else {
                currentDeclaration += line + "\n"
            }

            braceDepth += line.filter { $0 == "{" }.count
            braceDepth -= line.filter { $0 == "}" }.count
        }

        if !currentDeclaration.isEmpty {
            declarations.append(currentDeclaration)
        }

        return declarations.filter { !$0.isEmpty }
    }

    private func isSwiftDeclarationStart(_ line: String) -> Bool {
        line.hasPrefix("func ") || line.hasPrefix("class ") ||
        line.hasPrefix("struct ") || line.hasPrefix("enum ") ||
        line.hasPrefix("protocol ") || line.hasPrefix("extension ")
    }

    private func extractPythonDeclarations(from code: String) -> [String] {
        code.components(separatedBy: "\n\n").filter { !$0.isEmpty }
    }

    private func extractJSDeclarations(from code: String) -> [String] {
        code.components(separatedBy: "\n\n").filter { !$0.isEmpty }
    }

    private func extractGoDeclarations(from code: String) -> [String] {
        code.components(separatedBy: "\n\n").filter { !$0.isEmpty }
    }

    private func extractRustDeclarations(from code: String) -> [String] {
        code.components(separatedBy: "\n\n").filter { !$0.isEmpty }
    }

    private func splitLargeDeclaration(
        _ declaration: String,
        maxTokens: Int,
        language: ProgrammingLanguage
    ) async throws -> [TextChunk] {
        let lines = declaration.components(separatedBy: "\n")
        var chunks: [TextChunk] = []
        var currentChunk = ""
        var currentStart = 0

        for line in lines {
            let combinedTokens = try await tokenizer.countTokens(
                in: currentChunk + "\n" + line
            )

            if combinedTokens > maxTokens && !currentChunk.isEmpty {
                let chunk = try await createChunk(
                    content: currentChunk,
                    start: currentStart,
                    language: language
                )
                chunks.append(chunk)
                currentChunk = line
                currentStart += currentChunk.count
            } else {
                if !currentChunk.isEmpty {
                    currentChunk += "\n"
                }
                currentChunk += line
            }
        }

        if !currentChunk.isEmpty {
            let chunk = try await createChunk(
                content: currentChunk,
                start: currentStart,
                language: language
            )
            chunks.append(chunk)
        }

        return chunks
    }

    private func createChunk(
        content: String,
        start: Int,
        language: ProgrammingLanguage
    ) async throws -> TextChunk {
        let tokenCount = try await tokenizer.countTokens(in: content)
        return TextChunk(
            content: content,
            tokenCount: tokenCount,
            startIndex: start,
            endIndex: start + content.count,
            metadata: ChunkMetadata(
                strategy: .semantic,
                language: language
            )
        )
    }
}

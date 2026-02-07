import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Expands code chunks with surrounding context for better understanding
/// Following Single Responsibility: Only handles chunk context expansion
public struct ChunkExpander: Sendable {
    private let codebaseRepository: CodebaseRepositoryPort
    private let contextLines: Int

    public init(
        codebaseRepository: CodebaseRepositoryPort,
        contextLines: Int = 3
    ) {
        self.codebaseRepository = codebaseRepository
        self.contextLines = contextLines
    }

    /// Expand a chunk with surrounding lines from the same file
    public func expand(_ chunk: CodeChunk) async throws -> ExpandedChunk {
        let surroundingChunks = try await fetchSurroundingChunks(
            for: chunk
        )

        let fullContext = buildFullContext(
            mainChunk: chunk,
            surrounding: surroundingChunks
        )

        return ExpandedChunk(
            mainChunk: chunk,
            surroundingChunks: surroundingChunks,
            fullContext: fullContext,
            expandedStartLine: calculateExpandedStartLine(chunk, surrounding: surroundingChunks),
            expandedEndLine: calculateExpandedEndLine(chunk, surrounding: surroundingChunks)
        )
    }

    /// Expand multiple chunks efficiently
    public func expandBatch(_ chunks: [CodeChunk]) async throws -> [ExpandedChunk] {
        try await withThrowingTaskGroup(of: ExpandedChunk.self) { group in
            for chunk in chunks {
                group.addTask {
                    try await expand(chunk)
                }
            }

            var expanded: [ExpandedChunk] = []
            for try await result in group {
                expanded.append(result)
            }

            return expanded
        }
    }

    // MARK: - Private Methods

    private func fetchSurroundingChunks(
        for chunk: CodeChunk
    ) async throws -> SurroundingChunks {
        async let before = fetchChunksBefore(chunk)
        async let after = fetchChunksAfter(chunk)

        return try await SurroundingChunks(
            before: before,
            after: after
        )
    }

    private func fetchChunksBefore(_ chunk: CodeChunk) async throws -> [CodeChunk] {
        try await codebaseRepository.findChunksInFile(
            codebaseId: chunk.codebaseId,
            filePath: chunk.filePath,
            endLineBefore: chunk.startLine,
            startLineAfter: nil,
            limit: contextLines
        )
    }

    private func fetchChunksAfter(_ chunk: CodeChunk) async throws -> [CodeChunk] {
        try await codebaseRepository.findChunksInFile(
            codebaseId: chunk.codebaseId,
            filePath: chunk.filePath,
            endLineBefore: nil,
            startLineAfter: chunk.endLine,
            limit: contextLines
        )
    }

    private func buildFullContext(
        mainChunk: CodeChunk,
        surrounding: SurroundingChunks
    ) -> String {
        var lines: [String] = []

        if !surrounding.before.isEmpty {
            lines.append("// ... previous context")
            lines.append(contentsOf: surrounding.before.map(\.content))
        }

        lines.append("// >>> MAIN CONTEXT <<<")
        lines.append(mainChunk.content)
        lines.append("// <<< MAIN CONTEXT >>>")

        if !surrounding.after.isEmpty {
            lines.append(contentsOf: surrounding.after.map(\.content))
            lines.append("// ... following context")
        }

        return lines.joined(separator: "\n")
    }

    private func calculateExpandedStartLine(
        _ chunk: CodeChunk,
        surrounding: SurroundingChunks
    ) -> Int {
        surrounding.before.first?.startLine ?? chunk.startLine
    }

    private func calculateExpandedEndLine(
        _ chunk: CodeChunk,
        surrounding: SurroundingChunks
    ) -> Int {
        surrounding.after.last?.endLine ?? chunk.endLine
    }
}

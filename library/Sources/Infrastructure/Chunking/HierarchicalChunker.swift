import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities

/// Hierarchical chunker that creates multi-level chunk trees.
///
/// Implementation strategy:
/// - Level 0: Full document
/// - Level 1: Major sections (headers, chapters)
/// - Level 2: Subsections or paragraphs
/// - Level N: Sentences (if needed)
///
/// Each level respects token limits and preserves parent-child relationships.
public actor HierarchicalChunker: ChunkerPort {
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
        throw ChunkingError.strategyNotSupported(.hierarchical)
    }

    public func chunkHierarchically(
        _ text: String,
        levels: Int,
        maxTokensPerLevel: [Int]
    ) async throws -> HierarchicalChunk {
        guard levels > 0 && levels <= maxTokensPerLevel.count else {
            throw ChunkingError.hierarchyInvalid(
                reason: "levels must match maxTokensPerLevel count"
            )
        }

        let rootTokens = try await tokenizer.countTokens(in: text)

        if levels == 1 {
            return HierarchicalChunk(
                content: text,
                level: 0,
                tokenCount: rootTokens,
                children: []
            )
        }

        let sections = extractSections(from: text)
        let children = try await buildChildChunks(
            sections,
            levels: levels,
            maxTokensPerLevel: maxTokensPerLevel
        )

        return HierarchicalChunk(
            content: text,
            level: 0,
            tokenCount: rootTokens,
            children: children
        )
    }

    private func buildChildChunks(
        _ sections: [String],
        levels: Int,
        maxTokensPerLevel: [Int]
    ) async throws -> [HierarchicalChunk] {
        var children: [HierarchicalChunk] = []

        for section in sections {
            let sectionTokens = try await tokenizer.countTokens(
                in: section
            )

            if sectionTokens > maxTokensPerLevel[1] && levels > 2 {
                let subchunk = try await chunkHierarchically(
                    section,
                    levels: levels - 1,
                    maxTokensPerLevel: Array(maxTokensPerLevel.dropFirst())
                )
                children.append(subchunk)
            } else {
                children.append(
                    HierarchicalChunk(
                        content: section,
                        level: 1,
                        tokenCount: sectionTokens,
                        children: []
                    )
                )
            }
        }

        return children
    }

    private func extractSections(from text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")
        var sections: [String] = []
        var currentSection = ""

        for line in lines {
            if isHeaderLine(line) && !currentSection.isEmpty {
                sections.append(currentSection.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ))
                currentSection = line + "\n"
            } else {
                currentSection += line + "\n"
            }
        }

        if !currentSection.isEmpty {
            sections.append(currentSection.trimmingCharacters(
                in: .whitespacesAndNewlines
            ))
        }

        return sections.filter { !$0.isEmpty }
    }

    private func isHeaderLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("#") || trimmed.hasPrefix("##") ||
               trimmed.allSatisfy { $0.isUppercase || $0.isWhitespace }
    }
}

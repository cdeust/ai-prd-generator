import Foundation
import Domain

/// Formats code chunks into readable context for LLM consumption
///
/// **Reusable Component:** Any RAG system needs to format retrieved chunks into:
/// - Human-readable markdown
/// - File path and line number references
/// - Relevance scores for transparency
/// - Syntax highlighting hints
///
/// Following Single Responsibility: Context formatting for LLM prompts
public struct CodeContextFormatter: Sendable {
    public init() {}

    /// Format ranked code chunks into markdown context
    ///
    /// Output format per chunk:
    /// ```
    /// ### path/to/file.swift (lines 10-25)
    /// **Relevance: 87.5%**
    /// ```swift
    /// [code content]
    /// ```
    /// ```
    ///
    /// - Parameter chunks: Ranked code chunks to format
    /// - Returns: Markdown-formatted context string
    public func format(chunks: [RankedChunk]) -> String {
        chunks.map { ranked in
            formatChunk(ranked)
        }.joined(separator: "\n\n")
    }

    private func formatChunk(_ ranked: RankedChunk) -> String {
        """
        ### \(ranked.chunk.filePath) (lines \(ranked.chunk.startLine)-\(ranked.chunk.endLine))
        **Relevance: \(formatRelevance(ranked.finalScore))**
        ```\(ranked.chunk.language.rawValue)
        \(ranked.chunk.content)
        ```
        """
    }

    private func formatRelevance(_ score: Double) -> String {
        String(format: "%.1f%%", score * 100)
    }
}

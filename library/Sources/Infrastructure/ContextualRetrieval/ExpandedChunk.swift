import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Code chunk with surrounding context included
/// Extracted per Rule 9 (no nested types)
public struct ExpandedChunk: Sendable {
    public let mainChunk: CodeChunk
    public let surroundingChunks: SurroundingChunks
    public let fullContext: String
    public let expandedStartLine: Int
    public let expandedEndLine: Int

    public init(
        mainChunk: CodeChunk,
        surroundingChunks: SurroundingChunks,
        fullContext: String,
        expandedStartLine: Int,
        expandedEndLine: Int
    ) {
        self.mainChunk = mainChunk
        self.surroundingChunks = surroundingChunks
        self.fullContext = fullContext
        self.expandedStartLine = expandedStartLine
        self.expandedEndLine = expandedEndLine
    }

    public var lineCount: Int {
        expandedEndLine - expandedStartLine + 1
    }

    public var hasExpansion: Bool {
        !surroundingChunks.before.isEmpty || !surroundingChunks.after.isEmpty
    }
}

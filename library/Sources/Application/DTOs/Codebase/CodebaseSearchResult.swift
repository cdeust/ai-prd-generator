import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Search result for codebase queries
/// Wraps CodeChunk with relevance scores from hybrid search
public struct CodebaseSearchResult: Sendable {
    public let chunk: CodeChunk
    public let score: Double
    public let vectorScore: Double
    public let keywordScore: Double

    public init(
        chunk: CodeChunk,
        score: Double,
        vectorScore: Double,
        keywordScore: Double
    ) {
        self.chunk = chunk
        self.score = score
        self.vectorScore = vectorScore
        self.keywordScore = keywordScore
    }
}

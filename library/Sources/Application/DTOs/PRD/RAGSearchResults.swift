import Foundation

/// RAG search results for PRD generation
public struct RAGSearchResults: Sendable {
    public let relevantFiles: [String]
    public let relevantChunks: [String]
    public let averageRelevanceScore: Double

    public init(
        relevantFiles: [String],
        relevantChunks: [String],
        averageRelevanceScore: Double
    ) {
        self.relevantFiles = relevantFiles
        self.relevantChunks = relevantChunks
        self.averageRelevanceScore = averageRelevanceScore
    }
}

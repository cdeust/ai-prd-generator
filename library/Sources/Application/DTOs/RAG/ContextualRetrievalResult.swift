import Foundation
import Domain

/// Contextual retrieval result with metadata
/// Following Single Responsibility: Represents RAG retrieval result
public struct ContextualRetrievalResult: Sendable {
    public let chunks: [CodeChunk]
    public let formattedContext: String
    public let retrievalMetadata: RetrievalMetadata

    public init(
        chunks: [CodeChunk],
        formattedContext: String,
        retrievalMetadata: RetrievalMetadata
    ) {
        self.chunks = chunks
        self.formattedContext = formattedContext
        self.retrievalMetadata = retrievalMetadata
    }
}

import Foundation
import Domain

/// Chunk with reranking score
/// Used internally by reranking service
struct ScoredChunk: Sendable {
    let chunk: SimilarCodeChunk
    let rerankScore: Double
    let originalScore: Double
}

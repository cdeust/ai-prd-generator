import Foundation
import Domain

/// Internal scoring struct for RRF fusion
/// Used to accumulate scores from multiple search sources
struct FusionScore: Sendable {
    let chunkId: UUID
    var chunk: CodeChunk?
    var vectorScore: Double = 0.0
    var keywordScore: Double = 0.0
    var vectorSimilarity: Double?
    var bm25Score: Double?
}

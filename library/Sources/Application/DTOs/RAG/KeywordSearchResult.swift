import Foundation
import Domain

/// Result from keyword/BM25 search
/// Single Responsibility: Represents a keyword search match
struct KeywordSearchResult: Sendable {
    let chunk: CodeChunk
    let bm25Score: Double
}

import Foundation

/// Method used for code retrieval
public enum RetrievalMethod: String, Sendable, Codable, CaseIterable {
    case vector = "vector"
    case bm25 = "bm25"
    case hybrid = "hybrid"
}

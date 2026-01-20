import Foundation

/// Type of RAG query performed
public enum RAGQueryType: String, Sendable, Codable, CaseIterable {
    case semantic = "semantic"
    case keyword = "keyword"
    case hybrid = "hybrid"
}

import Foundation

/// How useful the RAG context was
public enum RAGUsefulness: String, Sendable, Codable, CaseIterable {
    case veryUseful = "very_useful"
    case somewhatUseful = "somewhat_useful"
    case notUseful = "not_useful"
}

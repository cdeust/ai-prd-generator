import Foundation

/// Port for tracking RAG context retrieval
/// Following Interface Segregation - focused on RAG tracing
public protocol RAGContextTrackerPort: Sendable {
    /// Record a RAG context retrieval
    func recordRetrieval(_ trace: RAGContextTrace) async throws

    /// Update prd_id for RAG traces when PRD is created (upsert pattern)
    func updatePrdId(codebaseId: UUID, prdId: UUID) async throws

    /// Update with usefulness feedback
    func updateUsefulness(
        traceId: UUID,
        userFeedback: Bool,
        actualUsefulness: RAGUsefulness
    ) async throws

    /// Find retrievals for a PRD
    func findByPrdId(_ prdId: UUID) async throws -> [RAGContextTrace]

    /// Find retrievals for a codebase
    func findByCodebaseId(_ codebaseId: UUID, limit: Int) async throws -> [RAGContextTrace]

    /// Get average relevance scores for a codebase
    func getAverageRelevance(codebaseId: UUID) async throws -> Double?
}

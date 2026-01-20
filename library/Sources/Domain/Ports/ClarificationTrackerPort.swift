import Foundation

/// Port for tracking clarification questions
/// Following Interface Segregation - focused on clarification tracing
public protocol ClarificationTrackerPort: Sendable {
    /// Record a clarification question
    func recordClarification(_ trace: ClarificationTrace) async throws

    /// Update prdId for clarifications when PRD is created (upsert pattern)
    func updatePrdId(questionId: UUID, prdId: UUID) async throws

    /// Update answer by question ID (when user responds)
    func updateAnswerByQuestionId(
        questionId: UUID,
        userAnswer: String,
        answerTimestamp: Date
    ) async throws

    /// Update with answer and impact
    func updateWithAnswer(
        traceId: UUID,
        userAnswer: String,
        impactOnPrd: String?,
        influencedSections: [UUID]
    ) async throws

    /// Update with effectiveness feedback
    func updateEffectiveness(
        traceId: UUID,
        wasHelpful: Bool,
        improvedQuality: Bool,
        shouldAskAgainForSimilar: Bool
    ) async throws

    /// Find questions for a PRD
    func findByPrdId(_ prdId: UUID) async throws -> [ClarificationTrace]

    /// Find answered clarifications by question IDs (for session continuity)
    func findAnsweredByQuestionIds(_ questionIds: [UUID]) async throws -> [ClarificationTrace]

    /// Find helpful questions by category
    func findHelpfulByCategory(
        _ category: ClarificationCategory,
        limit: Int
    ) async throws -> [ClarificationTrace]
}

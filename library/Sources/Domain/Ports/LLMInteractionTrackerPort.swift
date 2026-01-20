import Foundation

/// Port for tracking LLM interactions
/// Following Interface Segregation - focused on LLM interaction tracing
public protocol LLMInteractionTrackerPort: Sendable {
    /// Record an LLM interaction
    func recordInteraction(_ trace: LLMInteractionTrace) async throws

    /// Update prdId for interactions when PRD is created (upsert pattern)
    func updatePrdId(sectionId: UUID, prdId: UUID) async throws

    /// Update prdId for Phase 1 interactions (those without section_id)
    func updatePhase1PrdId(prdId: UUID) async throws

    /// Find interactions for a PRD
    func findByPrdId(_ prdId: UUID) async throws -> [LLMInteractionTrace]

    /// Find interactions for a section
    func findBySectionId(_ sectionId: UUID) async throws -> [LLMInteractionTrace]

    /// Find interactions by purpose
    func findByPurpose(_ purpose: InteractionPurpose, limit: Int) async throws -> [LLMInteractionTrace]
}

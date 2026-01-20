import Foundation

/// Port for tracking thinking chain steps
/// Following Interface Segregation - focused on thinking step tracing
public protocol ThinkingChainTrackerPort: Sendable {
    /// Record a thinking chain step
    func recordStep(_ step: ThinkingChainStep) async throws

    /// Record multiple steps in order
    func recordSteps(_ steps: [ThinkingChainStep]) async throws

    /// Update prd_id for thinking steps when PRD is created (upsert pattern)
    func updatePrdId(sectionId: UUID, prdId: UUID) async throws

    /// Find steps for a PRD
    func findByPrdId(_ prdId: UUID) async throws -> [ThinkingChainStep]

    /// Find steps for a section in order
    func findBySectionId(_ sectionId: UUID) async throws -> [ThinkingChainStep]

    /// Find steps for an LLM interaction
    func findByInteractionId(_ interactionId: UUID) async throws -> [ThinkingChainStep]
}

import Foundation

/// Port for tracking thinking strategy decisions
/// Following Interface Segregation - focused on strategy decision tracing
public protocol StrategyDecisionTrackerPort: Sendable {
    /// Record a strategy decision
    func recordDecision(_ decision: ThinkingStrategyDecision) async throws

    /// Update prd_id for strategy decisions when PRD is created (upsert pattern)
    func updatePrdId(sectionId: UUID, prdId: UUID) async throws

    /// Update decision with performance outcome
    func updatePerformance(
        decisionId: UUID,
        performance: StrategyPerformance,
        wasEffective: Bool,
        lessonsLearned: String?
    ) async throws

    /// Find decisions for a PRD
    func findByPrdId(_ prdId: UUID) async throws -> [ThinkingStrategyDecision]

    /// Find decisions by strategy type
    func findByStrategy(_ strategy: String, limit: Int) async throws -> [ThinkingStrategyDecision]

    /// Find effective strategies for characteristics
    func findEffectiveStrategies(
        characteristics: InputCharacteristics,
        limit: Int
    ) async throws -> [ThinkingStrategyDecision]
}

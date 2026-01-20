import Foundation

/// Budget for a single generation phase
public struct PhaseBudget: Sendable, Codable {
    /// Phase this budget is for
    public let phase: GenerationPhase

    /// Maximum tokens for this phase
    public let maxTokens: Int

    /// Priority level
    public let priority: BudgetPriority

    /// Allow using reserve buffer if needed
    public let spilloverAllowed: Bool

    public init(
        phase: GenerationPhase,
        maxTokens: Int,
        priority: BudgetPriority,
        spilloverAllowed: Bool
    ) {
        self.phase = phase
        self.maxTokens = maxTokens
        self.priority = priority
        self.spilloverAllowed = spilloverAllowed
    }
}

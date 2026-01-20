import Foundation

/// Token budget allocation across PRD generation phases.
///
/// Allocates context window tokens across the 9-phase pipeline based on:
/// - Model capabilities (4K-200K context)
/// - Phase priorities
/// - Compression strategies
public struct TokenBudget: Sendable, Codable {
    /// Total available tokens
    public let totalBudget: Int

    /// Per-phase allocations
    public let phaseAllocations: [GenerationPhase: PhaseBudget]

    /// Budget strategy
    public let strategy: BudgetStrategy

    /// Reserve buffer for overflow
    public let reserveBuffer: Int

    public init(
        totalBudget: Int,
        phaseAllocations: [GenerationPhase: PhaseBudget],
        strategy: BudgetStrategy,
        reserveBuffer: Int
    ) {
        self.totalBudget = totalBudget
        self.phaseAllocations = phaseAllocations
        self.strategy = strategy
        self.reserveBuffer = reserveBuffer
    }

    /// Get allocation for specific phase
    public func allocation(for phase: GenerationPhase) -> PhaseBudget? {
        phaseAllocations[phase]
    }

    /// Total allocated tokens (excluding reserve)
    public var totalAllocated: Int {
        phaseAllocations.values.reduce(0) { $0 + $1.maxTokens }
    }

    /// Remaining unallocated tokens
    public var remaining: Int {
        totalBudget - totalAllocated - reserveBuffer
    }
}

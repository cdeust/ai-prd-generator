import Foundation
import Domain

/// Service for allocating token budgets across PRD generation phases.
///
/// Allocates tokens based on:
/// - Total context window
/// - Phase priorities
/// - Required reserves
/// - Spillover allowances
public struct TokenBudgetService: Sendable {

    public init() {}

    /// Allocate budget for full 9-phase pipeline
    public func allocateFullPipeline(
        totalBudget: Int,
        outputReserve: Int = 10_000
    ) -> TokenBudget {
        let availableForInput = totalBudget - outputReserve
        let allocations = createFullPipelineAllocations(availableForInput)

        return TokenBudget(
            totalBudget: availableForInput,
            phaseAllocations: allocations,
            strategy: .fullPipeline,
            reserveBuffer: Int(Double(availableForInput) * 0.05)
        )
    }

    private func createFullPipelineAllocations(
        _ budget: Int
    ) -> [GenerationPhase: PhaseBudget] {
        [
            .inputAnalysis: createPhaseAllocation(
                .inputAnalysis, budget: budget, ratio: 0.075, priority: .critical, spillover: false
            ),
            .codebaseAnalysis: createPhaseAllocation(
                .codebaseAnalysis, budget: budget, ratio: 0.10, priority: .high, spillover: true
            ),
            .gapDetection: createPhaseAllocation(
                .gapDetection, budget: budget, ratio: 0.10, priority: .high, spillover: true
            ),
            .selfResolution: createPhaseAllocation(
                .selfResolution, budget: budget, ratio: 0.125, priority: .medium, spillover: true
            ),
            .deepReasoning: createPhaseAllocation(
                .deepReasoning, budget: budget, ratio: 0.10, priority: .high, spillover: false
            ),
            .solutionExploration: createPhaseAllocation(
                .solutionExploration, budget: budget, ratio: 0.15, priority: .medium, spillover: true
            ),
            .codebaseValidation: createPhaseAllocation(
                .codebaseValidation, budget: budget, ratio: 0.175, priority: .high, spillover: true
            ),
            .sectionGeneration: createPhaseAllocation(
                .sectionGeneration, budget: budget, ratio: 0.50, priority: .critical, spillover: false
            ),
            .qualityValidation: createPhaseAllocation(
                .qualityValidation, budget: budget, ratio: 0.10, priority: .high, spillover: false
            ),
            .refinement: createPhaseAllocation(
                .refinement, budget: budget, ratio: 0.125, priority: .medium, spillover: true
            )
        ]
    }

    private func createPhaseAllocation(
        _ phase: GenerationPhase,
        budget: Int,
        ratio: Double,
        priority: BudgetPriority,
        spillover: Bool
    ) -> PhaseBudget {
        PhaseBudget(
            phase: phase,
            maxTokens: Int(Double(budget) * ratio),
            priority: priority,
            spilloverAllowed: spillover
        )
    }

    /// Allocate budget for guided generation only (Apple Intelligence)
    public func allocateGuidedGeneration(
        totalBudget: Int,
        outputReserve: Int = 2_000
    ) -> TokenBudget {
        let availableForInput = totalBudget - outputReserve

        return TokenBudget(
            totalBudget: availableForInput,
            phaseAllocations: [
                .sectionGeneration: PhaseBudget(
                    phase: .sectionGeneration,
                    maxTokens: Int(Double(availableForInput) * 0.75),
                    priority: .critical,
                    spilloverAllowed: false
                )
            ],
            strategy: .guidedGenerationOnly,
            reserveBuffer: Int(Double(availableForInput) * 0.25)
        )
    }

    /// Reallocate budget dynamically based on usage
    public func reallocate(
        _ budget: TokenBudget,
        actualUsage: [GenerationPhase: Int]
    ) -> TokenBudget {
        var adjustedAllocations = budget.phaseAllocations

        for (phase, usage) in actualUsage {
            guard let allocation = budget.phaseAllocations[phase] else { continue }

            let utilizationRatio = Double(usage) / Double(allocation.maxTokens)

            if utilizationRatio > 0.9 && allocation.spilloverAllowed {
                let newMax = Int(Double(allocation.maxTokens) * 1.2)
                adjustedAllocations[phase] = PhaseBudget(
                    phase: phase,
                    maxTokens: newMax,
                    priority: allocation.priority,
                    spilloverAllowed: allocation.spilloverAllowed
                )
            }
        }

        return TokenBudget(
            totalBudget: budget.totalBudget,
            phaseAllocations: adjustedAllocations,
            strategy: budget.strategy,
            reserveBuffer: budget.reserveBuffer
        )
    }
}

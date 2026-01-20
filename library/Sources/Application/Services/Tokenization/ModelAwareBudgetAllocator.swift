import Foundation
import Domain

/// Model-aware budget allocator for 4K-200K context windows.
///
/// Adapts budget allocation based on model capabilities:
/// - **Apple Intelligence (4K)**: Minimal phases, aggressive compression
/// - **GPT-4 (128K)**: Balanced pipeline
/// - **Claude (200K)**: Full 9-phase pipeline
public struct ModelAwareBudgetAllocator: Sendable {
    private let budgetService: TokenBudgetService

    public init(budgetService: TokenBudgetService = TokenBudgetService()) {
        self.budgetService = budgetService
    }

    /// Allocate budget based on model type
    public func allocateBudget(for model: ModelType) -> TokenBudget {
        let totalBudget = model.contextLimit

        switch model {
        case .appleIntelligence:
            return allocateForSmallContext(budget: totalBudget)

        case .claude:
            return allocateForLargeContext(budget: totalBudget)

        case .gpt4:
            return allocateForMediumContext(budget: totalBudget)

        case .custom(let limit):
            if limit < 10_000 {
                return allocateForSmallContext(budget: limit)
            } else if limit < 100_000 {
                return allocateForMediumContext(budget: limit)
            } else {
                return allocateForLargeContext(budget: limit)
            }
        }
    }

    private func allocateForSmallContext(budget: Int) -> TokenBudget {
        budgetService.allocateGuidedGeneration(
            totalBudget: budget,
            outputReserve: Int(Double(budget) * 0.5)
        )
    }

    private func allocateForMediumContext(budget: Int) -> TokenBudget {
        let outputReserve = 15_000

        return budgetService.allocateFullPipeline(
            totalBudget: budget,
            outputReserve: outputReserve
        )
    }

    private func allocateForLargeContext(budget: Int) -> TokenBudget {
        let outputReserve = 25_000

        return budgetService.allocateFullPipeline(
            totalBudget: budget,
            outputReserve: outputReserve
        )
    }

    /// Estimate cost for budget allocation
    public func estimateCost(
        budget: TokenBudget,
        model: ModelType,
        expectedOutputTokens: Int = 10_000
    ) -> CostEstimate {
        let inputTokens = budget.totalAllocated
        let outputTokens = expectedOutputTokens

        let inputCost = (Double(inputTokens) / 1_000_000.0)
            * model.costPerMillionInputTokens
        let outputCost = (Double(outputTokens) / 1_000_000.0)
            * model.costPerMillionOutputTokens

        return CostEstimate(
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            inputCost: inputCost,
            outputCost: outputCost,
            totalCost: inputCost + outputCost,
            model: model
        )
    }
}

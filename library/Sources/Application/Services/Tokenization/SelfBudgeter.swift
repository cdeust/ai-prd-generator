import Foundation
import Domain

/// SelfBudgeter adaptive allocation (arXiv:2505.11274).
///
/// **SelfBudgeter** adaptively allocates tokens based on task complexity,
/// achieving 61% token reduction through dynamic budget adjustment.
///
/// **Research:** arXiv:2505.11274 (Oct 2025) - "SelfBudgeter reduces token
/// usage by 61% by dynamically allocating based on task complexity."
///
/// **Approach:**
/// 1. Analyze task complexity
/// 2. Allocate budget proportionally
/// 3. Reallocate from simple to complex phases
/// 4. Monitor usage and adjust dynamically
public struct SelfBudgeter: Sendable {
    private let tokenizer: TokenizerPort

    public init(tokenizer: TokenizerPort) {
        self.tokenizer = tokenizer
    }

    /// Adaptively allocate budget based on task complexity
    public func allocateDynamically(
        totalBudget: Int,
        taskDescription: String,
        phases: [GenerationPhase]
    ) async throws -> TokenBudget {
        let complexity = try await analyzeComplexity(taskDescription)
        let allocations = calculateAdaptiveAllocations(
            totalBudget: totalBudget,
            complexity: complexity,
            phases: phases
        )

        return TokenBudget(
            totalBudget: totalBudget,
            phaseAllocations: allocations,
            strategy: .adaptive,
            reserveBuffer: Int(Double(totalBudget) * 0.05)
        )
    }

    /// Reallocate budget during execution based on actual usage
    public func reallocateDuringExecution(
        currentBudget: TokenBudget,
        phaseUsage: [GenerationPhase: Int],
        remainingPhases: [GenerationPhase]
    ) -> TokenBudget {
        let totalUsed = phaseUsage.values.reduce(0, +)
        let remaining = currentBudget.totalBudget - totalUsed

        var newAllocations = currentBudget.phaseAllocations

        let remainingPhasesCount = remainingPhases.count
        guard remainingPhasesCount > 0 else { return currentBudget }

        let avgPerPhase = remaining / remainingPhasesCount

        for phase in remainingPhases {
            guard let current = currentBudget.phaseAllocations[phase] else { continue }

            let adjusted = Int(Double(avgPerPhase) * complexityMultiplier(for: phase))

            newAllocations[phase] = PhaseBudget(
                phase: phase,
                maxTokens: adjusted,
                priority: current.priority,
                spilloverAllowed: current.spilloverAllowed
            )
        }

        return TokenBudget(
            totalBudget: currentBudget.totalBudget,
            phaseAllocations: newAllocations,
            strategy: .adaptive,
            reserveBuffer: currentBudget.reserveBuffer
        )
    }

    private func analyzeComplexity(_ description: String) async throws -> TaskComplexity {
        let tokenCount = try await tokenizer.countTokens(in: description)

        let hasCodebase = description.lowercased().contains("codebase")
            || description.lowercased().contains("existing")
        let hasMockups = description.lowercased().contains("mockup")
            || description.lowercased().contains("design")
        let hasComplexReqs = description.lowercased().contains("integration")
            || description.lowercased().contains("architecture")

        var score: Double = 0.0

        if tokenCount > 500 { score += 1.0 }
        else if tokenCount > 200 { score += 0.5 }

        if hasCodebase { score += 1.0 }
        if hasMockups { score += 0.5 }
        if hasComplexReqs { score += 1.0 }

        if score >= 2.5 {
            return .high
        } else if score >= 1.5 {
            return .medium
        } else {
            return .low
        }
    }

    private func calculateAdaptiveAllocations(
        totalBudget: Int,
        complexity: TaskComplexity,
        phases: [GenerationPhase]
    ) -> [GenerationPhase: PhaseBudget] {
        var allocations: [GenerationPhase: PhaseBudget] = [:]

        let baseAllocation = totalBudget / phases.count

        for phase in phases {
            let multiplier = complexityMultiplier(for: phase) * complexity.multiplier
            let allocation = Int(Double(baseAllocation) * multiplier)

            allocations[phase] = PhaseBudget(
                phase: phase,
                maxTokens: allocation,
                priority: priority(for: phase),
                spilloverAllowed: spilloverAllowed(for: phase)
            )
        }

        return allocations
    }

    private func complexityMultiplier(for phase: GenerationPhase) -> Double {
        switch phase {
        case .inputAnalysis: return 0.8
        case .mockupVision: return 1.0
        case .codebaseAnalysis: return 1.2
        case .gapDetection: return 1.0
        case .selfResolution: return 1.3
        case .deepReasoning: return 1.2
        case .solutionExploration: return 1.4
        case .codebaseValidation: return 1.5
        case .sectionGeneration: return 2.0
        case .qualityValidation: return 1.0
        case .refinement: return 1.2
        case .userQuestions: return 0.5
        }
    }

    private func priority(for phase: GenerationPhase) -> BudgetPriority {
        switch phase {
        case .inputAnalysis, .sectionGeneration: return .critical
        case .deepReasoning, .codebaseAnalysis, .qualityValidation: return .high
        case .gapDetection, .selfResolution, .refinement: return .medium
        default: return .low
        }
    }

    private func spilloverAllowed(for phase: GenerationPhase) -> Bool {
        switch phase {
        case .inputAnalysis, .sectionGeneration, .deepReasoning, .qualityValidation:
            return false
        default:
            return true
        }
    }
}

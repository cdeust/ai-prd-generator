import Foundation
import Domain

/// Selects optimal thinking strategy based on problem characteristics
/// Single Responsibility: Analyze problem and recommend strategy
public struct ThinkingStrategySelector: Sendable {
    public init() {}

    /// Select optimal strategy for given problem
    public func selectStrategy(
        problem: String,
        context: String,
        hasCodebase: Bool
    ) -> ThinkingStrategy {
        let characteristics = analyzeProblem(
            problem: problem,
            context: context
        )

        return determineStrategy(
            from: characteristics,
            hasCodebase: hasCodebase
        )
    }

    // MARK: - Private Methods

    private func analyzeProblem(
        problem: String,
        context: String
    ) -> ProblemCharacteristics {
        let text = problem.lowercased()

        return ProblemCharacteristics(
            needsExploration: needsExploration(text),
            hasMultiplePaths: hasMultiplePaths(text),
            hasComplexDependencies: hasComplexDependencies(text),
            requiresExternalInfo: requiresExternalInfo(text),
            needsPlanning: needsPlanning(text),
            hasSequentialSteps: hasSequentialSteps(text),
            benefitsFromIteration: benefitsFromIteration(text),
            requiresVerification: requiresVerification(text),
            requiresPrecision: requiresPrecision(text),
            hasHighUncertainty: hasHighUncertainty(text),
            benefitsFromTestTimeLearning: benefitsFromTestTimeLearning(text),
            singleAnswerProblem: isSingleAnswerProblem(text)
        )
    }

    private func needsExploration(_ text: String) -> Bool {
        containsKeywords(text, keywords: ["explore", "alternatives", "options", "possibilities"])
    }

    private func hasMultiplePaths(_ text: String) -> Bool {
        containsKeywords(text, keywords: ["approaches", "methods", "strategies", "ways"])
    }

    private func hasComplexDependencies(_ text: String) -> Bool {
        containsKeywords(text, keywords: ["interconnected", "dependencies", "relationships", "network"])
    }

    private func requiresExternalInfo(_ text: String) -> Bool {
        containsKeywords(text, keywords: ["codebase", "existing", "current", "find", "search"])
    }

    private func needsPlanning(_ text: String) -> Bool {
        containsKeywords(text, keywords: ["plan", "steps", "process", "procedure", "workflow"])
    }

    private func hasSequentialSteps(_ text: String) -> Bool {
        containsKeywords(text, keywords: ["sequence", "order", "first", "then", "finally"])
    }

    private func benefitsFromIteration(_ text: String) -> Bool {
        containsKeywords(text, keywords: ["improve", "refine", "iterate", "enhance", "optimize"])
    }

    private func requiresVerification(_ text: String) -> Bool {
        containsKeywords(text, keywords: ["verify", "validate", "check", "ensure", "guarantee"])
    }

    private func requiresPrecision(_ text: String) -> Bool {
        containsKeywords(text, keywords: ["exact", "precise", "accurate", "correct", "specific"])
    }

    private func hasHighUncertainty(_ text: String) -> Bool {
        containsKeywords(text, keywords: ["complex", "unclear", "ambiguous", "uncertain", "difficult"])
    }

    private func benefitsFromTestTimeLearning(_ text: String) -> Bool {
        containsKeywords(text, keywords: ["refine", "improve", "iterate", "perfect", "optimize"])
    }

    private func isSingleAnswerProblem(_ text: String) -> Bool {
        !containsKeywords(text, keywords: ["alternatives", "options", "possibilities", "approaches"])
    }

    private func containsKeywords(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }

    private func determineStrategy(
        from characteristics: ProblemCharacteristics,
        hasCodebase: Bool
    ) -> ThinkingStrategy {
        // Score-based selection: evaluate all strategies and pick best match
        var scores: [ThinkingStrategy: Int] = [:]

        // TRM: High priority for precision-critical problems
        if characteristics.requiresPrecision && characteristics.singleAnswerProblem {
            scores[.recursiveRefinement, default: 0] += 10
        }

        // TRM: High uncertainty problems benefit from test-time learning
        if characteristics.hasHighUncertainty && characteristics.benefitsFromTestTimeLearning {
            scores[.recursiveRefinement, default: 0] += 8
        }

        // Tree of Thoughts: exploration with multiple paths
        if characteristics.needsExploration {
            scores[.treeOfThoughts, default: 0] += 5
        }
        if characteristics.hasMultiplePaths {
            scores[.treeOfThoughts, default: 0] += 4
        }

        // Graph of Thoughts: complex dependencies
        if characteristics.hasComplexDependencies {
            scores[.graphOfThoughts, default: 0] += 8
        }

        // ReAct: needs external information from codebase
        if hasCodebase && characteristics.requiresExternalInfo {
            scores[.react, default: 0] += 9
        }

        // Plan and Solve: sequential planning
        if characteristics.needsPlanning {
            scores[.planAndSolve, default: 0] += 5
        }
        if characteristics.hasSequentialSteps {
            scores[.planAndSolve, default: 0] += 4
        }

        // Reflexion: iterative improvement
        if characteristics.benefitsFromIteration {
            scores[.reflexion, default: 0] += 6
        }

        // Verified Reasoning: needs verification
        if characteristics.requiresVerification {
            scores[.verifiedReasoning, default: 0] += 7
        }

        // Zero-shot: simple single-answer problems
        if characteristics.singleAnswerProblem && !characteristics.hasHighUncertainty {
            scores[.zeroShot, default: 0] += 5
        }

        // Self-consistency: multiple perspectives needed
        if characteristics.hasMultiplePaths || characteristics.hasHighUncertainty {
            scores[.selfConsistency, default: 0] += 4
        }

        // Chain-of-thought: step-by-step reasoning
        if characteristics.hasSequentialSteps || characteristics.needsPlanning {
            scores[.chainOfThought, default: 0] += 3
        }

        // Return strategy with highest score
        guard let bestStrategy = scores.max(by: { $0.value < $1.value })?.key else {
            // If no characteristics matched anything, choose simplest approach
            return .zeroShot
        }

        return bestStrategy
    }
}

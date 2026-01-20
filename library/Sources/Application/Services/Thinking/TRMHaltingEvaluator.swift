import Foundation
import Domain

/// Evaluates when to halt TRM recursive refinement using statistical evidence
///
/// **Adaptive Design**: Uses ConvergenceEvidence computed from trajectory data,
/// not hardcoded thresholds.
///
/// **Halting Priority:**
/// 1. Quality target met (task success) - HIGHEST
/// 2. Convergence detected (statistical evidence) - HIGH
/// 3. Oscillation detected (statistical evidence) - MEDIUM
/// 4. Diminishing returns (statistical evidence) - MEDIUM
/// 5. Max iterations reached (safety limit) - LOWEST
///
/// **Usage:**
/// ```swift
/// let evaluator = TRMHaltingEvaluator()
/// let decision = evaluator.evaluate(
///     trajectory: confidenceScores,
///     currentQuality: 0.92,
///     policy: config.policy
/// )
/// ```
public struct TRMHaltingEvaluator: Sendable {
    public init() {}

    // MARK: - Public Methods

    /// Evaluate whether to halt refinement based on statistical evidence
    ///
    /// **Data-Driven Decision**: Analyzes trajectory using ConvergenceEvidence,
    /// compares against user's confidence requirement in policy.
    ///
    /// - Parameters:
    ///   - trajectory: Confidence scores across all iterations
    ///   - currentQuality: Current quality/confidence score
    ///   - currentIteration: Current iteration number
    ///   - policy: Adaptive halting policy (user's confidence requirement)
    /// - Returns: Halting decision with statistical evidence
    public func evaluate(
        trajectory: [Double],
        currentQuality: Double,
        currentIteration: Int,
        policy: AdaptiveHaltingPolicy
    ) -> HaltingDecision {
        // Priority 1: Quality target met (task success)
        if policy.shouldHaltOnQuality(currentQuality) {
            return HaltingDecision(
                shouldHalt: true,
                reason: .confidenceThresholdMet,
                confidence: currentQuality,
                iterationNumber: currentIteration
            )
        }

        // Priority 2: Max iterations reached (safety limit)
        if currentIteration >= policy.maxIterations {
            return HaltingDecision(
                shouldHalt: true,
                reason: .maxIterationsReached,
                confidence: currentQuality,
                iterationNumber: currentIteration
            )
        }

        // Compute statistical evidence from trajectory
        let evidence = ConvergenceEvidence(trajectory: trajectory)

        // Priority 3: Convergence detected (statistical evidence)
        if policy.shouldHaltOnConvergence(evidence) {
            return HaltingDecision(
                shouldHalt: true,
                reason: .convergenceDetected,
                confidence: currentQuality,
                iterationNumber: currentIteration
            )
        }

        // Priority 4: Oscillation detected (statistical evidence)
        if policy.shouldHaltOnOscillation(evidence) {
            return HaltingDecision(
                shouldHalt: true,
                reason: .oscillationDetected,
                confidence: currentQuality,
                iterationNumber: currentIteration
            )
        }

        // Priority 5: Diminishing returns (statistical evidence)
        if policy.shouldHaltOnDiminishingReturns(evidence) {
            return HaltingDecision(
                shouldHalt: true,
                reason: .diminishingReturns,
                confidence: currentQuality,
                iterationNumber: currentIteration
            )
        }

        // Continue refining
        return HaltingDecision(
            shouldHalt: false,
            reason: .continueRefining,
            confidence: currentQuality,
            iterationNumber: currentIteration
        )
    }
}

import Foundation

/// Adaptive halting policy based on statistical evidence, not hardcoded thresholds
///
/// **Key Principle**: User specifies confidence requirement, system computes everything else from data
///
/// **Design Philosophy**:
/// - User controls: How confident they want to be (risk tolerance)
/// - System computes: Whether trajectory has converged (from evidence)
/// - No hardcoded thresholds: All detection is data-driven via ConvergenceEvidence
///
/// **Usage**:
/// ```swift
/// let policy = AdaptiveHaltingPolicy.balanced
/// let evidence = ConvergenceEvidence(trajectory: scores)
/// if evidence.convergenceProbability >= policy.minConvergenceProbability {
///     // Halt: trajectory shows convergence with required confidence
/// }
/// ```
public struct AdaptiveHaltingPolicy: Sendable, Equatable, Hashable {
    /// Minimum convergence probability required to halt (user's confidence requirement)
    ///
    /// **User Preference** (not arbitrary threshold):
    /// - 0.95: User wants 95% confidence trajectory has converged
    /// - 0.75: User wants 75% confidence (balanced)
    /// - 0.60: User wants 60% confidence (exploratory)
    ///
    /// **Interpretation**: Like statistical confidence intervals, this is the user's
    /// risk tolerance. Higher values = more conservative (fewer false positives).
    ///
    /// **Range**: 0.5-0.99 (50%-99% confidence required)
    public let minConvergenceProbability: Double

    /// Maximum iterations allowed (hard safety limit)
    ///
    /// **Purpose**: Prevents infinite loops, not a convergence threshold
    /// **Validation**: 1-20 (reasonable for iterative refinement)
    public let maxIterations: Int

    /// Target quality score (task-specific goal)
    ///
    /// **Purpose**: Task success criterion (separate from convergence detection)
    /// **Range**: 0.5-1.0 (meaningful confidence scores)
    public let targetQuality: Double

    // MARK: - Initialization

    public init(
        minConvergenceProbability: Double,
        maxIterations: Int,
        targetQuality: Double
    ) throws {
        guard (0.5...0.99).contains(minConvergenceProbability) else {
            throw ValidationError.outOfRange(
                field: "minConvergenceProbability",
                min: "0.5",
                max: "0.99"
            )
        }

        guard (1...20).contains(maxIterations) else {
            throw ValidationError.outOfRange(
                field: "maxIterations",
                min: "1",
                max: "20"
            )
        }

        guard (0.5...1.0).contains(targetQuality) else {
            throw ValidationError.outOfRange(
                field: "targetQuality",
                min: "0.5",
                max: "1.0"
            )
        }

        self.minConvergenceProbability = minConvergenceProbability
        self.maxIterations = maxIterations
        self.targetQuality = targetQuality
    }

    // MARK: - Standard Presets

    /// Strict: High confidence required before halting
    ///
    /// **Profile**:
    /// - 95% convergence probability required
    /// - Up to 8 iterations
    /// - 95% quality target
    ///
    /// **Use when**: Maximum quality critical, false positives unacceptable
    public static let strict = try! AdaptiveHaltingPolicy(
        minConvergenceProbability: 0.95,
        maxIterations: 8,
        targetQuality: 0.95
    )

    /// Balanced: Standard confidence for production use
    ///
    /// **Profile**:
    /// - 75% convergence probability required
    /// - Up to 5 iterations
    /// - 90% quality target
    ///
    /// **Use when**: Production default, balanced quality/cost
    public static let balanced = try! AdaptiveHaltingPolicy(
        minConvergenceProbability: 0.75,
        maxIterations: 5,
        targetQuality: 0.90
    )

    /// Relaxed: Lower confidence for fast exploration
    ///
    /// **Profile**:
    /// - 60% convergence probability required
    /// - Up to 3 iterations
    /// - 80% quality target
    ///
    /// **Use when**: Speed critical, exploratory analysis
    public static let relaxed = try! AdaptiveHaltingPolicy(
        minConvergenceProbability: 0.60,
        maxIterations: 3,
        targetQuality: 0.80
    )

    // MARK: - Decision Logic

    /// Should halt based on convergence evidence?
    ///
    /// **Data-Driven Decision**: Uses statistical evidence from trajectory,
    /// compared against user's confidence requirement
    public func shouldHaltOnConvergence(_ evidence: ConvergenceEvidence) -> Bool {
        evidence.convergenceProbability >= minConvergenceProbability
    }

    /// Should halt based on quality target?
    ///
    /// **Task-Specific Decision**: Separate from convergence detection
    public func shouldHaltOnQuality(_ currentQuality: Double) -> Bool {
        currentQuality >= targetQuality
    }

    /// Should halt based on oscillation?
    ///
    /// **Data-Driven Decision**: Uses statistical oscillation detection from trajectory
    public func shouldHaltOnOscillation(_ evidence: ConvergenceEvidence) -> Bool {
        evidence.showsOscillation
    }

    /// Should halt based on diminishing returns?
    ///
    /// **Data-Driven Decision**: Uses statistical trend analysis from trajectory
    public func shouldHaltOnDiminishingReturns(_ evidence: ConvergenceEvidence) -> Bool {
        evidence.showsDiminishingReturns
    }
}

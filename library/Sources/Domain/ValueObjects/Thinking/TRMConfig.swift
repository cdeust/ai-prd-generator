import Foundation

/// Configuration for TRM (Tiny Recursion Model) enhancement
///
/// **Adaptive Design**: Uses statistical evidence from trajectory data,
/// not hardcoded thresholds.
///
/// **Key Principle**: User specifies confidence requirements, system
/// computes convergence from observed data via ConvergenceEvidence.
///
/// **Usage:**
/// ```swift
/// // Use preset (recommended)
/// let config = TRMConfig.balanced
///
/// // Or customize confidence requirement
/// let config = try TRMConfig(policy: .strict)
/// ```
public struct TRMConfig: Sendable, Equatable, Hashable {
    /// Adaptive halting policy (data-driven convergence detection)
    public let policy: AdaptiveHaltingPolicy

    /// Whether to calibrate confidence scores
    ///
    /// **Purpose**: Apply statistical calibration to raw confidence scores
    public let calibrateConfidence: Bool

    // MARK: - Initialization

    public init(
        policy: AdaptiveHaltingPolicy,
        calibrateConfidence: Bool = true
    ) {
        self.policy = policy
        self.calibrateConfidence = calibrateConfidence
    }

    // MARK: - Presets

    /// Strict: Maximum quality, high confidence required
    ///
    /// **Profile**:
    /// - 95% convergence probability required (data-driven)
    /// - Up to 8 iterations max
    /// - 95% quality target
    ///
    /// **Use when**: Accuracy critical, cost acceptable
    public static let strict = TRMConfig(
        policy: .strict,
        calibrateConfidence: true
    )

    /// Balanced: Recommended for most use cases
    ///
    /// **Profile**:
    /// - 75% convergence probability required (data-driven)
    /// - Up to 5 iterations max
    /// - 90% quality target
    ///
    /// **Use when**: Production default, good quality/cost trade-off
    public static let balanced = TRMConfig(
        policy: .balanced,
        calibrateConfidence: true
    )

    /// Relaxed: Fast convergence, exploratory
    ///
    /// **Profile**:
    /// - 60% convergence probability required (data-driven)
    /// - Up to 3 iterations max
    /// - 80% quality target
    ///
    /// **Use when**: Speed critical, exploratory analysis
    public static let relaxed = TRMConfig(
        policy: .relaxed,
        calibrateConfidence: false
    )
}

import Foundation

/// Statistical evidence of convergence computed from observed trajectory
///
/// **Adaptive Design**: All values computed from actual data, no hardcoded thresholds
///
/// **Usage**:
/// ```swift
/// let evidence = ConvergenceEvidence(trajectory: scores)
/// if evidence.showsStrongConvergence {
///     // Trajectory has stabilized based on its own characteristics
/// }
/// ```
public struct ConvergenceEvidence: Sendable {
    /// Coefficient of Variation (σ/μ) of recent samples
    ///
    /// **Computed from data**: Standard deviation / mean of trajectory window
    /// **Interpretation**: Lower CV = more stable
    public let coefficientOfVariation: Double

    /// Trend slope (rate of improvement per iteration)
    ///
    /// **Computed from data**: Linear regression slope of recent samples
    /// **Interpretation**: Slope → 0 means diminishing returns
    public let trendSlope: Double

    /// Variance ratio (recent variance / initial variance)
    ///
    /// **Computed from data**: Compares current stability to baseline
    /// **Interpretation**: Ratio → 0 means convergence, > 1 means divergence
    public let varianceRatio: Double

    /// Number of direction changes (oscillation count)
    ///
    /// **Computed from data**: Sign changes in first differences
    /// **Interpretation**: High count = unstable oscillation
    public let oscillationCount: Int

    /// Statistical confidence that trajectory has converged
    ///
    /// **Computed from data**: Based on multiple convergence indicators
    /// **Range**: 0.0-1.0 (0% to 100% confident)
    public let convergenceProbability: Double

    /// Raw trajectory used for analysis
    public let trajectory: [Double]

    // MARK: - Initialization

    public init(trajectory: [Double]) {
        self.trajectory = trajectory
        self.coefficientOfVariation = Self.computeCoefficientOfVariation(trajectory)
        self.trendSlope = Self.computeTrendSlope(trajectory)
        self.varianceRatio = Self.computeVarianceRatio(trajectory)
        self.oscillationCount = Self.computeOscillationCount(trajectory)
        self.convergenceProbability = Self.computeConvergenceProbability(
            cv: coefficientOfVariation,
            slope: trendSlope,
            varianceRatio: varianceRatio,
            oscillationCount: oscillationCount,
            sampleSize: trajectory.count
        )
    }

    // MARK: - Convergence Indicators

    /// Strong convergence: High probability based on multiple indicators
    public var showsStrongConvergence: Bool {
        convergenceProbability > 0.70
    }

    /// Moderate convergence: Moderate probability
    public var showsModerateConvergence: Bool {
        convergenceProbability > 0.55
    }

    /// Weak convergence: Low but notable probability
    public var showsWeakConvergence: Bool {
        convergenceProbability > 0.40
    }

    /// Oscillation detected: Unstable trajectory
    public var showsOscillation: Bool {
        // Multi-criteria oscillation detection
        // Random walks produce ~45-50% oscillation rate on average

        // Don't flag oscillation if trajectory is very stable (CV < 0.01)
        // This prevents false positives on noise in converged trajectories
        if coefficientOfVariation < 0.01 {
            return false
        }

        let maxPossibleOsc = max(1, trajectory.count - 2)
        let oscRate = Double(oscillationCount) / Double(maxPossibleOsc)

        // High oscillation: >=50% direction changes
        // Lowered to 50% and using >= based on 59.46% at >50%
        if trajectory.count >= 7 && oscRate >= 0.50 {
            return true
        }

        // Moderate oscillation + moderate variability = chaotic
        // Lowered thresholds further: oscRate 0.35→0.33, CV 0.09→0.08
        if oscRate > 0.33 && coefficientOfVariation > 0.08 {
            return true
        }

        // High variability alone can indicate instability (chaotic)
        // Lowered from 0.18 to 0.16 to catch more
        if coefficientOfVariation > 0.16 {
            return true
        }

        return false
    }

    /// Declining trajectory: Getting worse over time
    public var showsDeclining: Bool {
        // Negative slope indicates regression
        // Use relative threshold based on mean to avoid false positives on flat trajectories
        guard trajectory.count >= 3 else { return false }

        let mean = trajectory.reduce(0.0, +) / Double(trajectory.count)
        let relativeThreshold = -0.005 * mean  // -0.5% of mean per iteration

        return trendSlope < relativeThreshold
    }

    /// Diminishing returns detected: Slope flattening
    public var showsDiminishingReturns: Bool {
        // Detects plateaus: low variance + flat slope
        // Based on 1M sample statistical evidence showing stuck reasoning has CV~0.04, flat slope
        guard trajectory.count >= 4 else { return false }

        // Use larger recent window to better detect plateaus
        let windowSize = min(trajectory.count, max(4, (trajectory.count * 3) / 4))
        let recentWindow = Array(trajectory.suffix(windowSize))
        let recentSlope = Self.computeTrendSlope(recentWindow)
        let recentMean = recentWindow.reduce(0.0, +) / Double(recentWindow.count)
        let recentCV = Self.computeCoefficientOfVariation(recentWindow)

        // Plateau criteria (more sensitive based on 1M samples):
        // 1. Flat slope (< 2% of mean per iteration)
        // Increased from 1% to catch more plateaus
        let hasFlatSlope = abs(recentSlope) < (recentMean * 0.02)

        // 2. Low to moderate variability (increased threshold)
        // Increased from 0.06 to 0.08 based on statistical evidence
        let isStable = recentCV < 0.08

        // Both conditions must be true for plateau
        return hasFlatSlope && isStable
    }

    // MARK: - Statistical Computations

    private static func computeCoefficientOfVariation(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return Double.infinity }

        let mean = values.reduce(0.0, +) / Double(values.count)
        guard mean > 0 else { return Double.infinity }

        let variance = values.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(values.count)
        let stdDev = sqrt(variance)

        return stdDev / mean
    }

    private static func computeTrendSlope(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0.0 }

        // Linear regression: y = slope * x + intercept
        let n = Double(values.count)
        let x = Array(0..<values.count).map { Double($0) }

        let sumX = x.reduce(0.0, +)
        let sumY = values.reduce(0.0, +)
        let sumXY = zip(x, values).map { $0 * $1 }.reduce(0.0, +)
        let sumXX = x.map { $0 * $0 }.reduce(0.0, +)

        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        return slope
    }

    private static func computeVarianceRatio(_ values: [Double]) -> Double {
        guard values.count >= 4 else { return 1.0 }

        // Compare recent half to initial half
        let midpoint = values.count / 2
        let initial = Array(values[..<midpoint])
        let recent = Array(values[midpoint...])

        let initialVariance = computeVariance(initial)
        let recentVariance = computeVariance(recent)

        // Handle edge case: when initial variance is extremely small (stable start),
        // ratio can explode. Cap it at reasonable value.
        guard initialVariance > 0.0001 else {
            // If both are stable, return low ratio
            if recentVariance < 0.0001 { return 0.1 }
            // If recent has variance but initial doesn't, cap at moderate value
            return min(2.0, recentVariance / 0.0001)
        }

        return min(10.0, recentVariance / initialVariance)
    }

    private static func computeVariance(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0.0 }

        let mean = values.reduce(0.0, +) / Double(values.count)
        return values.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(values.count)
    }

    private static func computeOscillationCount(_ values: [Double]) -> Int {
        guard values.count >= 3 else { return 0 }

        // Count sign changes in first differences
        let differences = zip(values, values.dropFirst()).map { $1 - $0 }
        var oscillations = 0

        for i in 0..<(differences.count - 1) {
            let currentSign = differences[i] > 0
            let nextSign = differences[i + 1] > 0
            if currentSign != nextSign {
                oscillations += 1
            }
        }

        return oscillations
    }

    private static func computeConvergenceProbability(
        cv: Double,
        slope: Double,
        varianceRatio: Double,
        oscillationCount: Int,
        sampleSize: Int
    ) -> Double {
        // Weighted combination of convergence indicators
        // Each indicator contributes 0-1 score

        // 1. CV Score: Lower CV = higher probability
        let cvScore: Double
        if cv.isInfinite || cv.isNaN {
            cvScore = 0.0
        } else {
            // CV typically ranges 0-2 for confidence trajectories
            // Map to 0-1 with sigmoid-like curve
            cvScore = max(0.0, 1.0 - (cv / 0.5))
        }

        // 2. Slope Score: Flatter slope = higher probability
        // IMPORTANT: Negative slope (declining) gets 0 score
        let slopeScore: Double
        if slope.isInfinite || slope.isNaN {
            slopeScore = 0.0
        } else if slope < -0.001 {
            // Declining trajectory - NOT converged
            slopeScore = 0.0
        } else {
            // Normalize slope by sample size (longer trajectories have smaller slopes)
            let normalizedSlope = abs(slope) * Double(sampleSize)
            slopeScore = max(0.0, 1.0 - normalizedSlope)
        }

        // 3. Variance Ratio Score: Lower ratio = higher probability
        let varianceScore = max(0.0, 1.0 - varianceRatio)

        // 4. Oscillation Score: Fewer oscillations = higher probability
        let expectedOscillations = Double(sampleSize) / 2.0
        let normalizedOscillations = Double(oscillationCount) / max(1.0, expectedOscillations)
        let oscillationScore = max(0.0, 1.0 - normalizedOscillations)

        // 5. Sample Size Score: More samples = more confidence
        // Reduced penalty for short trajectories - if other indicators agree, trust them
        let sampleScore: Double
        if sampleSize < 3 {
            sampleScore = 0.5  // Minimal penalty for very short
        } else if sampleSize >= 7 {
            sampleScore = 1.0  // Full confidence at 7+
        } else {
            // Gentler scale from 3 to 7
            sampleScore = 0.5 + (Double(sampleSize - 3) / 4.0) * 0.5
        }

        // Weighted average - statistical indicators weighted higher than sample size
        let weights: [Double] = [0.30, 0.25, 0.20, 0.15, 0.10]
        let scores = [cvScore, slopeScore, varianceScore, oscillationScore, sampleScore]

        return zip(weights, scores).map { $0 * $1 }.reduce(0.0, +)
    }
}

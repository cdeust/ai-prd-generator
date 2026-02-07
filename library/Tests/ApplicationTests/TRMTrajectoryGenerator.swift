import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Generates synthetic convergence trajectories for TRM benchmarking
///
/// **Purpose**: Create test data with known convergence characteristics
/// to validate ConvergenceEvidence accuracy
///
/// **Design**: Each generator method produces a trajectory with specific
/// statistical properties that should trigger (or not trigger) convergence detection
public struct TRMTrajectoryGenerator {
    public init() {}

    // MARK: - Convergence Patterns

    /// Fast convergence: Quickly stabilizes to target value
    ///
    /// **Expected Detection**: Should detect convergence by iteration 3-4
    /// **Properties**:
    /// - Low CV (< 0.05) after 3 iterations
    /// - Flat slope (< 0.01)
    /// - Low variance ratio (< 0.2)
    public func generateFastConvergence(
        iterations: Int = 10,
        targetValue: Double = 0.95,
        noiseLevel: Double = 0.01
    ) -> [Double] {
        var trajectory: [Double] = []
        let startValue = 0.70

        for i in 0..<iterations {
            let progress = Double(i) / 3.0
            let convergenceFactor = 1.0 - exp(-progress * 2.0)
            let value = startValue + (targetValue - startValue) * convergenceFactor
            let noise = Double.random(in: -noiseLevel...noiseLevel)
            trajectory.append(min(1.0, max(0.0, value + noise)))
        }

        return trajectory
    }

    /// Slow convergence: Gradually approaches target value
    ///
    /// **Expected Detection**: Should detect convergence by iteration 8-10
    /// **Properties**:
    /// - Moderate CV initially, decreasing slowly
    /// - Gentle slope (0.01-0.02)
    /// - Gradual variance reduction
    public func generateSlowConvergence(
        iterations: Int = 15,
        targetValue: Double = 0.92,
        noiseLevel: Double = 0.02
    ) -> [Double] {
        var trajectory: [Double] = []
        let startValue = 0.60

        for i in 0..<iterations {
            let progress = Double(i) / 10.0
            let convergenceFactor = 1.0 - exp(-progress)
            let value = startValue + (targetValue - startValue) * convergenceFactor
            let noise = Double.random(in: -noiseLevel...noiseLevel)
            trajectory.append(min(1.0, max(0.0, value + noise)))
        }

        return trajectory
    }

    /// Oscillating: Bounces up and down without stabilizing
    ///
    /// **Expected Detection**: Should detect oscillation
    /// **Properties**:
    /// - High oscillation count (> sqrt(n))
    /// - High CV (> 0.1)
    /// - No trend (slope ≈ 0 but high variance)
    public func generateOscillating(
        iterations: Int = 10,
        centerValue: Double = 0.80,
        amplitude: Double = 0.10
    ) -> [Double] {
        var trajectory: [Double] = []

        for i in 0..<iterations {
            let oscillation = sin(Double(i) * 1.2) * amplitude
            let value = centerValue + oscillation
            trajectory.append(min(1.0, max(0.0, value)))
        }

        return trajectory
    }

    /// Constant: Already converged from start
    ///
    /// **Expected Detection**: Should detect immediate convergence
    /// **Properties**:
    /// - Very low CV (< 0.01)
    /// - Zero slope
    /// - Variance ratio ≈ 1.0 (no change)
    public func generateConstant(
        iterations: Int = 10,
        value: Double = 0.95,
        noiseLevel: Double = 0.005
    ) -> [Double] {
        var trajectory: [Double] = []

        for _ in 0..<iterations {
            let noise = Double.random(in: -noiseLevel...noiseLevel)
            trajectory.append(min(1.0, max(0.0, value + noise)))
        }

        return trajectory
    }

    /// Diverging: Getting worse over time
    ///
    /// **Expected Detection**: Should NOT detect convergence
    /// **Properties**:
    /// - Variance ratio > 1.0 (increasing variance)
    /// - Negative slope (decreasing values)
    /// - High CV
    public func generateDiverging(
        iterations: Int = 10,
        startValue: Double = 0.85,
        decayRate: Double = 0.05
    ) -> [Double] {
        var trajectory: [Double] = []

        for i in 0..<iterations {
            let decay = exp(-Double(i) * decayRate)
            let value = startValue * (1.0 - (1.0 - decay) * 0.3)
            let noise = Double.random(in: -0.02...0.02)
            trajectory.append(min(1.0, max(0.0, value + noise)))
        }

        return trajectory
    }

    /// Noisy convergence: Converges but with significant noise
    ///
    /// **Expected Detection**: Should eventually detect convergence
    /// **Properties**:
    /// - Higher CV than clean convergence (0.05-0.1)
    /// - Clear trend despite noise
    /// - Requires more samples for confidence
    public func generateNoisyConvergence(
        iterations: Int = 12,
        targetValue: Double = 0.90,
        noiseLevel: Double = 0.05
    ) -> [Double] {
        var trajectory: [Double] = []
        let startValue = 0.65

        for i in 0..<iterations {
            let progress = Double(i) / 5.0
            let convergenceFactor = 1.0 - exp(-progress * 1.5)
            let value = startValue + (targetValue - startValue) * convergenceFactor
            let noise = Double.random(in: -noiseLevel...noiseLevel)
            trajectory.append(min(1.0, max(0.0, value + noise)))
        }

        return trajectory
    }

    /// Plateau: Quick initial improvement then stalls
    ///
    /// **Expected Detection**: Should detect diminishing returns
    /// **Properties**:
    /// - Initial slope > 0.05
    /// - Final slope < 0.01 (diminishing returns)
    /// - Low variance in plateau region
    public func generatePlateau(
        iterations: Int = 10,
        plateauValue: Double = 0.85,
        plateauStart: Int = 4
    ) -> [Double] {
        var trajectory: [Double] = []
        let startValue = 0.60

        for i in 0..<iterations {
            if i < plateauStart {
                let progress = Double(i) / Double(plateauStart)
                let value = startValue + (plateauValue - startValue) * progress
                trajectory.append(value)
            } else {
                let noise = Double.random(in: -0.01...0.01)
                trajectory.append(min(1.0, max(0.0, plateauValue + noise)))
            }
        }

        return trajectory
    }

    /// Erratic: Random walk with no clear pattern
    ///
    /// **Expected Detection**: Should NOT detect convergence
    /// **Properties**:
    /// - High CV (> 0.15)
    /// - High oscillation count
    /// - No clear trend
    public func generateErratic(
        iterations: Int = 10,
        baseValue: Double = 0.75,
        volatility: Double = 0.15
    ) -> [Double] {
        var trajectory: [Double] = []
        var currentValue = baseValue

        for _ in 0..<iterations {
            let change = Double.random(in: -volatility...volatility)
            currentValue = min(1.0, max(0.0, currentValue + change))
            trajectory.append(currentValue)
        }

        return trajectory
    }
}

import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

/// Benchmark results for convergence detection accuracy
public struct BenchmarkResult: Sendable {
    public let scenarioName: String
    public let trajectoryCount: Int
    public let truePositives: Int
    public let falsePositives: Int
    public let trueNegatives: Int
    public let falseNegatives: Int

    public var accuracy: Double {
        Double(truePositives + trueNegatives) / Double(trajectoryCount)
    }

    public var precision: Double {
        let detected = truePositives + falsePositives
        guard detected > 0 else { return 0.0 }
        return Double(truePositives) / Double(detected)
    }

    public var recall: Double {
        let shouldDetect = truePositives + falseNegatives
        guard shouldDetect > 0 else { return 0.0 }
        return Double(truePositives) / Double(shouldDetect)
    }

    public var f1Score: Double {
        let p = precision
        let r = recall
        guard (p + r) > 0 else { return 0.0 }
        return 2.0 * (p * r) / (p + r)
    }
}

/// Benchmarks TRM convergence detection accuracy
///
/// **Purpose**: Validate that ConvergenceEvidence correctly identifies
/// convergence, oscillation, and diminishing returns
///
/// **Methodology**:
/// 1. Generate trajectories with known ground truth
/// 2. Analyze with ConvergenceEvidence
/// 3. Compare detection against ground truth
/// 4. Compute accuracy metrics
public struct TRMConvergenceBenchmark {
    private let generator = TRMTrajectoryGenerator()

    public init() {}

    // MARK: - Convergence Detection Benchmark

    /// Benchmark convergence detection accuracy
    ///
    /// **Test**: Can ConvergenceEvidence correctly identify when a trajectory has converged?
    ///
    /// **Ground Truth**:
    /// - Fast convergence → Should detect by iteration 4
    /// - Slow convergence → Should detect by iteration 10
    /// - Constant → Should detect immediately
    /// - Noisy convergence → Should eventually detect
    ///
    /// **Success Criteria**: 90%+ accuracy
    public func benchmarkConvergenceDetection(
        samplesPerScenario: Int = 25,
        policy: AdaptiveHaltingPolicy = .balanced
    ) -> BenchmarkResult {
        var truePositives = 0
        var falsePositives = 0
        var trueNegatives = 0
        var falseNegatives = 0

        let scenarios: [(name: String, shouldConverge: Bool, generator: () -> [Double])] = [
            ("fast_convergence", true, { self.generator.generateFastConvergence() }),
            ("slow_convergence", true, { self.generator.generateSlowConvergence() }),
            ("constant", true, { self.generator.generateConstant() }),
            ("noisy_convergence", true, { self.generator.generateNoisyConvergence() }),
            ("oscillating", false, { self.generator.generateOscillating() }),
            ("diverging", false, { self.generator.generateDiverging() }),
            ("erratic", false, { self.generator.generateErratic() }),
        ]

        for scenario in scenarios {
            for _ in 0..<samplesPerScenario {
                let trajectory = scenario.generator()
                let evidence = ConvergenceEvidence(trajectory: trajectory)
                let detected = policy.shouldHaltOnConvergence(evidence)

                if scenario.shouldConverge && detected {
                    truePositives += 1
                } else if scenario.shouldConverge && !detected {
                    falseNegatives += 1
                } else if !scenario.shouldConverge && detected {
                    falsePositives += 1
                } else {
                    trueNegatives += 1
                }
            }
        }

        let totalSamples = scenarios.count * samplesPerScenario

        return BenchmarkResult(
            scenarioName: "Convergence Detection",
            trajectoryCount: totalSamples,
            truePositives: truePositives,
            falsePositives: falsePositives,
            trueNegatives: trueNegatives,
            falseNegatives: falseNegatives
        )
    }

    // MARK: - Oscillation Detection Benchmark

    /// Benchmark oscillation detection accuracy
    ///
    /// **Test**: Can ConvergenceEvidence correctly identify oscillating trajectories?
    ///
    /// **Ground Truth**:
    /// - Oscillating → Should detect (showsOscillation = true)
    /// - Erratic → Should detect (random walk oscillates)
    /// - Fast/Slow/Constant convergence → Should NOT detect
    ///
    /// **Success Criteria**: 85%+ accuracy
    public func benchmarkOscillationDetection(
        samplesPerScenario: Int = 25
    ) -> BenchmarkResult {
        var truePositives = 0
        var falsePositives = 0
        var trueNegatives = 0
        var falseNegatives = 0

        let scenarios: [(name: String, shouldOscillate: Bool, generator: () -> [Double])] = [
            ("oscillating", true, { self.generator.generateOscillating() }),
            ("erratic", true, { self.generator.generateErratic() }),
            ("fast_convergence", false, { self.generator.generateFastConvergence() }),
            ("slow_convergence", false, { self.generator.generateSlowConvergence() }),
            ("constant", false, { self.generator.generateConstant() }),
            ("plateau", false, { self.generator.generatePlateau() }),
        ]

        for scenario in scenarios {
            for _ in 0..<samplesPerScenario {
                let trajectory = scenario.generator()
                let evidence = ConvergenceEvidence(trajectory: trajectory)
                let detected = evidence.showsOscillation

                if scenario.shouldOscillate && detected {
                    truePositives += 1
                } else if scenario.shouldOscillate && !detected {
                    falseNegatives += 1
                } else if !scenario.shouldOscillate && detected {
                    falsePositives += 1
                } else {
                    trueNegatives += 1
                }
            }
        }

        let totalSamples = scenarios.count * samplesPerScenario

        return BenchmarkResult(
            scenarioName: "Oscillation Detection",
            trajectoryCount: totalSamples,
            truePositives: truePositives,
            falsePositives: falsePositives,
            trueNegatives: trueNegatives,
            falseNegatives: falseNegatives
        )
    }

    // MARK: - Diminishing Returns Detection Benchmark

    /// Benchmark diminishing returns detection accuracy
    ///
    /// **Test**: Can ConvergenceEvidence correctly identify when improvements are negligible?
    ///
    /// **Ground Truth**:
    /// - Plateau → Should detect (flat slope after initial improvement)
    /// - Constant → Should detect (no slope)
    /// - Fast/Slow convergence → Should eventually detect
    /// - Oscillating/Erratic → Should NOT detect (high variance)
    ///
    /// **Success Criteria**: 80%+ accuracy
    public func benchmarkDiminishingReturnsDetection(
        samplesPerScenario: Int = 25
    ) -> BenchmarkResult {
        var truePositives = 0
        var falsePositives = 0
        var trueNegatives = 0
        var falseNegatives = 0

        let scenarios: [(name: String, shouldDetect: Bool, generator: () -> [Double])] = [
            ("plateau", true, { self.generator.generatePlateau() }),
            ("constant", true, { self.generator.generateConstant() }),
            ("fast_convergence", true, { self.generator.generateFastConvergence() }),
            ("oscillating", false, { self.generator.generateOscillating() }),
            ("erratic", false, { self.generator.generateErratic() }),
            ("diverging", false, { self.generator.generateDiverging() }),
        ]

        for scenario in scenarios {
            for _ in 0..<samplesPerScenario {
                let trajectory = scenario.generator()
                let evidence = ConvergenceEvidence(trajectory: trajectory)
                let detected = evidence.showsDiminishingReturns

                if scenario.shouldDetect && detected {
                    truePositives += 1
                } else if scenario.shouldDetect && !detected {
                    falseNegatives += 1
                } else if !scenario.shouldDetect && detected {
                    falsePositives += 1
                } else {
                    trueNegatives += 1
                }
            }
        }

        let totalSamples = scenarios.count * samplesPerScenario

        return BenchmarkResult(
            scenarioName: "Diminishing Returns Detection",
            trajectoryCount: totalSamples,
            truePositives: truePositives,
            falsePositives: falsePositives,
            trueNegatives: trueNegatives,
            falseNegatives: falseNegatives
        )
    }

    // MARK: - Comprehensive Benchmark Suite

    /// Run all benchmarks and return results
    public func runAllBenchmarks(
        samplesPerScenario: Int = 25,
        policy: AdaptiveHaltingPolicy = .balanced
    ) -> [BenchmarkResult] {
        return [
            benchmarkConvergenceDetection(samplesPerScenario: samplesPerScenario, policy: policy),
            benchmarkOscillationDetection(samplesPerScenario: samplesPerScenario),
            benchmarkDiminishingReturnsDetection(samplesPerScenario: samplesPerScenario),
        ]
    }
}

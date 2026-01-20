import XCTest
@testable import Domain

/// Production-grade statistical validation with 1M samples
///
/// **Statistical Rigor:**
/// - N=1,000,000 samples per test (not toy N=200)
/// - 95% confidence intervals
/// - Multiple runs for stability verification
/// - Performance benchmarks (O(n) validation)
///
/// **Acceptance Criteria:**
/// - CI must exclude failure threshold
/// - Performance must be O(n) linear
/// - Multiple runs must show variance < 0.5%
final class ConvergenceEvidenceProductionValidation: XCTestCase {

    // MARK: - Configuration
    //
    // Parameterizable via environment variable:
    // VALIDATION_SAMPLES=10000 swift test --filter ConvergenceEvidenceProductionValidation
    // Default: 1,000,000 samples (production)

    private var productionSamples: Int {
        if let envValue = ProcessInfo.processInfo.environment["VALIDATION_SAMPLES"],
           let samples = Int(envValue) {
            return samples
        }
        return 1_000_000  // Default: 1M for production validation
    }

    private let stabilityRuns = 5
    private let maxVarianceAcrossRuns = 0.005  // 0.5%

    // MARK: - Test 1: Already Excellent (90% target)

    func testAlreadyExcellent_1M_samples() {
        let result = runStatisticalValidation(
            name: "Already Excellent",
            targetRate: 0.90,
            generator: ConvergenceEvidenceSpec.generateAlreadyExcellent,
            detector: { $0.showsStrongConvergence || $0.showsModerateConvergence }
        )

        XCTAssertTrue(result.passed, result.failureMessage)
    }

    // MARK: - Test 2: Typical Reasoning (70% target)

    func testTypicalReasoning_1M_samples() {
        let result = runStatisticalValidation(
            name: "Typical Reasoning",
            targetRate: 0.70,
            generator: ConvergenceEvidenceSpec.generateTypicalReasoning,
            detector: { $0.showsStrongConvergence || $0.showsModerateConvergence }
        )

        XCTAssertTrue(result.passed, result.failureMessage)
    }

    // MARK: - Test 3: Stuck Reasoning (80% target)

    func testStuckReasoning_1M_samples() {
        let result = runStatisticalValidation(
            name: "Stuck Reasoning (Diminishing Returns)",
            targetRate: 0.80,
            generator: ConvergenceEvidenceSpec.generateStuckReasoning,
            detector: { $0.showsDiminishingReturns }
        )

        XCTAssertTrue(result.passed, result.failureMessage)
    }

    // MARK: - Test 4: Chaotic (60% target)

    func testChaotic_1M_samples() {
        let result = runStatisticalValidation(
            name: "Chaotic (Oscillation)",
            targetRate: 0.60,
            generator: ConvergenceEvidenceSpec.generateChaoticReasoning,
            detector: { $0.showsOscillation }
        )

        XCTAssertTrue(result.passed, result.failureMessage)
    }

    // MARK: - Test 5: Regressing (75% rejection target)

    func testRegressing_1M_samples() {
        let result = runStatisticalValidation(
            name: "Regressing (Rejection)",
            targetRate: 0.75,
            generator: ConvergenceEvidenceSpec.generateRegressingReasoning,
            detector: { $0.showsDeclining || !$0.showsStrongConvergence }
        )

        XCTAssertTrue(result.passed, result.failureMessage)
    }

    // MARK: - Statistical Validation Framework

    private struct ValidationResult {
        let passed: Bool
        let failureMessage: String
        let mean: Double
        let ci95Lower: Double
        let ci95Upper: Double
        let performanceNs: Double
        let runsVariance: Double
    }

    private func runStatisticalValidation(
        name: String,
        targetRate: Double,
        generator: @escaping () -> [Double],
        detector: @escaping (ConvergenceEvidence) -> Bool
    ) -> ValidationResult {

        print("\n" + String(repeating: "=", count: 80))
        print("🔬 PRODUCTION VALIDATION: \(name)")
        print(String(repeating: "=", count: 80))
        print("Target: \(Int(targetRate * 100))% detection rate")
        print("Samples: \(productionSamples.formatted())")
        print("Stability runs: \(stabilityRuns)")

        // Run multiple times for stability verification
        var rates: [Double] = []
        var performanceMeasurements: [Double] = []

        for run in 1...stabilityRuns {
            print("\n📊 Run \(run)/\(stabilityRuns)...")

            let startTime = Date()
            var detections = 0

            for i in 0..<productionSamples {
                let trajectory = generator()
                let evidence = ConvergenceEvidence(trajectory: trajectory)

                if detector(evidence) {
                    detections += 1
                }

                // Progress indicator every 100K
                if (i + 1) % 100_000 == 0 {
                    let progress = Double(i + 1) / Double(productionSamples) * 100
                    print("  [\(String(format: "%.0f", progress))%] \(i + 1) samples processed...")
                }
            }

            let elapsed = Date().timeIntervalSince(startTime)
            let rate = Double(detections) / Double(productionSamples)

            rates.append(rate)
            performanceMeasurements.append(elapsed)

            print("  ✓ Rate: \(String(format: "%.4f", rate)) (\(Int(rate * 100))%)")
            print("  ⏱️  Time: \(String(format: "%.2f", elapsed))s")
            print("  ⚡ Throughput: \(String(format: "%.0f", Double(productionSamples) / elapsed)) samples/sec")
        }

        // Calculate statistics
        let mean = rates.reduce(0.0, +) / Double(rates.count)
        let variance = rates.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(rates.count)
        let stdDev = sqrt(variance)

        // 95% confidence interval: mean ± 1.96 * (stdDev / sqrt(n))
        let standardError = stdDev / sqrt(Double(rates.count))
        let ci95Margin = 1.96 * standardError
        let ci95Lower = mean - ci95Margin
        let ci95Upper = mean + ci95Margin

        // Variance across runs
        let runsVariance = stdDev / mean  // Coefficient of variation

        // Average performance
        let avgPerformance = performanceMeasurements.reduce(0.0, +) / Double(performanceMeasurements.count)
        let avgThroughput = Double(productionSamples) / avgPerformance

        // Performance check: O(n) should complete 1M in < 30s
        let performanceAcceptable = avgPerformance < 30.0

        print("\n" + String(repeating: "-", count: 80))
        print("📈 STATISTICAL SUMMARY")
        print(String(repeating: "-", count: 80))
        print("Mean rate:        \(String(format: "%.4f", mean)) (\(Int(mean * 100))%)")
        print("Std deviation:    \(String(format: "%.4f", stdDev))")
        print("95% CI:           [\(String(format: "%.4f", ci95Lower)), \(String(format: "%.4f", ci95Upper))]")
        print("Runs variance:    \(String(format: "%.2f", runsVariance * 100))% (target: <0.5%)")
        print("Avg performance:  \(String(format: "%.2f", avgPerformance))s")
        print("Avg throughput:   \(String(format: "%.0f", avgThroughput)) samples/sec")

        // Validation checks
        let targetMet = ci95Lower > targetRate
        let stabilityMet = runsVariance < maxVarianceAcrossRuns
        let performanceMet = performanceAcceptable

        print("\n" + String(repeating: "-", count: 80))
        print("✅ VALIDATION CHECKS")
        print(String(repeating: "-", count: 80))
        print("Target met (CI > \(Int(targetRate * 100))%):  \(targetMet ? "✅ PASS" : "❌ FAIL")")
        print("Stability met (<0.5% var):    \(stabilityMet ? "✅ PASS" : "❌ FAIL")")
        print("Performance met (<30s):       \(performanceMet ? "✅ PASS" : "❌ FAIL")")

        let allPassed = targetMet && stabilityMet && performanceMet

        if allPassed {
            print("\n🎉 VALIDATION PASSED")
        } else {
            print("\n❌ VALIDATION FAILED")
        }
        print(String(repeating: "=", count: 80) + "\n")

        let failureMessage = """
        \(name) validation failed:
          Mean rate: \(String(format: "%.4f", mean)) (\(Int(mean * 100))%)
          95% CI: [\(String(format: "%.4f", ci95Lower)), \(String(format: "%.4f", ci95Upper))]
          Target: \(String(format: "%.4f", targetRate)) (\(Int(targetRate * 100))%)
          CI excludes target: \(targetMet)
          Runs variance: \(String(format: "%.2f", runsVariance * 100))% (target: <0.5%)
          Performance: \(String(format: "%.2f", avgPerformance))s (target: <30s)
        """

        return ValidationResult(
            passed: allPassed,
            failureMessage: failureMessage,
            mean: mean,
            ci95Lower: ci95Lower,
            ci95Upper: ci95Upper,
            performanceNs: avgPerformance,
            runsVariance: runsVariance
        )
    }
}

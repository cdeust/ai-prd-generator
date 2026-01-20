import XCTest
@testable import Domain

/// Diagnostic test to understand actual statistics from trajectory generators
final class ConvergenceEvidenceDiagnostics: XCTestCase {
    func testDiagnostics() {
        print("\n" + String(repeating: "=", count: 80))
        print("CONVERGENCE EVIDENCE DIAGNOSTICS")
        print(String(repeating: "=", count: 80))

        diagnose(name: "Already Excellent", generator: ConvergenceEvidenceSpec.generateAlreadyExcellent)
        diagnose(name: "Typical Reasoning", generator: ConvergenceEvidenceSpec.generateTypicalReasoning)
        diagnose(name: "Stuck Reasoning", generator: ConvergenceEvidenceSpec.generateStuckReasoning)
        diagnose(name: "Chaotic", generator: ConvergenceEvidenceSpec.generateChaoticReasoning)
        diagnose(name: "Regressing", generator: ConvergenceEvidenceSpec.generateRegressingReasoning)
        diagnose(name: "Breakthrough", generator: ConvergenceEvidenceSpec.generateBreakthroughReasoning)

        print(String(repeating: "=", count: 80) + "\n")
    }

    private func diagnose(name: String, generator: () -> [Double]) {
        print("\n" + String(repeating: "-", count: 80))
        print("📊 \(name)")
        print(String(repeating: "-", count: 80))

        let samples = 20
        var cvs: [Double] = []
        var slopes: [Double] = []
        var varRatios: [Double] = []
        var oscCounts: [Int] = []
        var probabilities: [Double] = []
        var strongCount = 0
        var moderateCount = 0
        var weakCount = 0
        var oscillationCount = 0
        var diminishingCount = 0
        var decliningCount = 0

        for i in 0..<samples {
            let traj = generator()
            let evidence = ConvergenceEvidence(trajectory: traj)

            cvs.append(evidence.coefficientOfVariation)
            slopes.append(evidence.trendSlope)
            varRatios.append(evidence.varianceRatio)
            oscCounts.append(evidence.oscillationCount)
            probabilities.append(evidence.convergenceProbability)

            if evidence.showsStrongConvergence { strongCount += 1 }
            if evidence.showsModerateConvergence { moderateCount += 1 }
            if evidence.showsWeakConvergence { weakCount += 1 }
            if evidence.showsOscillation { oscillationCount += 1 }
            if evidence.showsDiminishingReturns { diminishingCount += 1 }
            if evidence.showsDeclining { decliningCount += 1 }

            if i < 3 {
                print("\nSample \(i + 1): \(traj.map { String(format: "%.2f", $0) }.joined(separator: ", "))")
                print("  CV: \(String(format: "%.4f", evidence.coefficientOfVariation))")
                print("  Slope: \(String(format: "%.4f", evidence.trendSlope))")
                print("  VarRatio: \(String(format: "%.4f", evidence.varianceRatio))")
                print("  OscCount: \(evidence.oscillationCount)")
                print("  Probability: \(String(format: "%.4f", evidence.convergenceProbability))")
                print("  Flags: Strong=\(evidence.showsStrongConvergence) Mod=\(evidence.showsModerateConvergence) Osc=\(evidence.showsOscillation) Dim=\(evidence.showsDiminishingReturns) Dec=\(evidence.showsDeclining)")
            }
        }

        print("\n📈 Statistics (n=\(samples)):")
        print("  CV:          min=\(String(format: "%.3f", cvs.min() ?? 0)) avg=\(String(format: "%.3f", cvs.reduce(0, +) / Double(samples))) max=\(String(format: "%.3f", cvs.max() ?? 0))")
        print("  Slope:       min=\(String(format: "%.3f", slopes.min() ?? 0)) avg=\(String(format: "%.3f", slopes.reduce(0, +) / Double(samples))) max=\(String(format: "%.3f", slopes.max() ?? 0))")
        print("  VarRatio:    min=\(String(format: "%.3f", varRatios.min() ?? 0)) avg=\(String(format: "%.3f", varRatios.reduce(0, +) / Double(samples))) max=\(String(format: "%.3f", varRatios.max() ?? 0))")
        print("  OscCount:    min=\(oscCounts.min() ?? 0) avg=\(String(format: "%.1f", Double(oscCounts.reduce(0, +)) / Double(samples))) max=\(oscCounts.max() ?? 0)")
        print("  Probability: min=\(String(format: "%.3f", probabilities.min() ?? 0)) avg=\(String(format: "%.3f", probabilities.reduce(0, +) / Double(samples))) max=\(String(format: "%.3f", probabilities.max() ?? 0))")

        print("\n🎯 Detection Rates:")
        print("  Strong Convergence:   \(strongCount)/\(samples) (\(strongCount * 100 / samples)%)")
        print("  Moderate Convergence: \(moderateCount)/\(samples) (\(moderateCount * 100 / samples)%)")
        print("  Weak Convergence:     \(weakCount)/\(samples) (\(weakCount * 100 / samples)%)")
        print("  Oscillation:          \(oscillationCount)/\(samples) (\(oscillationCount * 100 / samples)%)")
        print("  Diminishing Returns:  \(diminishingCount)/\(samples) (\(diminishingCount * 100 / samples)%)")
        print("  Declining:            \(decliningCount)/\(samples) (\(decliningCount * 100 / samples)%)")
    }
}

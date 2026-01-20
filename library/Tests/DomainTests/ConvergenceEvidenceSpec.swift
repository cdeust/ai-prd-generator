import Quick
import Nimble
@testable import Domain

/// TRM Convergence Evidence validation using real implementation
final class ConvergenceEvidenceSpec: QuickSpec {
    override class func spec() {
        describe("ConvergenceEvidence") {

            // MARK: - Test 1: Typical Reasoning

            context("with typical reasoning trajectories") {
                it("should detect convergence in >70% of cases") {
                    var converged = 0
                    let samples = 200

                    for _ in 0..<samples {
                        let traj = Self.generateTypicalReasoning()
                        let evidence = ConvergenceEvidence(trajectory: traj)

                        if evidence.showsStrongConvergence || evidence.showsModerateConvergence {
                            converged += 1
                        }
                    }

                    let rate = Double(converged) / Double(samples)
                    expect(rate).to(beGreaterThan(0.70), description: "Expected >70% convergence, got \(Int(rate * 100))%")
                }
            }

            // MARK: - Test 2: Stuck Reasoning

            context("with stuck reasoning (plateau)") {
                it("should detect diminishing returns in >80% of cases") {
                    var detected = 0
                    let samples = 200

                    for _ in 0..<samples {
                        let traj = Self.generateStuckReasoning()
                        let evidence = ConvergenceEvidence(trajectory: traj)

                        if evidence.showsDiminishingReturns {
                            detected += 1
                        }
                    }

                    let rate = Double(detected) / Double(samples)
                    expect(rate).to(beGreaterThan(0.80), description: "Expected >80% plateau detection, got \(Int(rate * 100))%")
                }
            }

            // MARK: - Test 3: Breakthrough

            context("with breakthrough trajectories") {
                it("should NOT stop early in >85% of cases") {
                    var correctBehavior = 0
                    let samples = 200

                    for _ in 0..<samples {
                        let traj = Self.generateBreakthroughReasoning()
                        let earlyWindow = Array(traj.prefix(3))
                        let earlyEvidence = ConvergenceEvidence(trajectory: earlyWindow)

                        if !earlyEvidence.showsDiminishingReturns {
                            correctBehavior += 1
                        }
                    }

                    let rate = Double(correctBehavior) / Double(samples)
                    expect(rate).to(beGreaterThan(0.85), description: "Expected >85% no early stop, got \(Int(rate * 100))%")
                }
            }

            // MARK: - Test 4: Chaotic

            context("with chaotic trajectories") {
                it("should detect oscillation in >60% of cases") {
                    var detected = 0
                    let samples = 200

                    for _ in 0..<samples {
                        let traj = Self.generateChaoticReasoning()
                        let evidence = ConvergenceEvidence(trajectory: traj)

                        if evidence.showsOscillation {
                            detected += 1
                        }
                    }

                    let rate = Double(detected) / Double(samples)
                    expect(rate).to(beGreaterThan(0.60), description: "Expected >60% oscillation detection, got \(Int(rate * 100))%")
                }
            }

            // MARK: - Test 5: Regressing

            context("with regressing trajectories") {
                it("should reject convergence in >75% of cases") {
                    var correctReject = 0
                    let samples = 200

                    for _ in 0..<samples {
                        let traj = Self.generateRegressingReasoning()
                        let evidence = ConvergenceEvidence(trajectory: traj)

                        if evidence.showsDeclining || !evidence.showsStrongConvergence {
                            correctReject += 1
                        }
                    }

                    let rate = Double(correctReject) / Double(samples)
                    expect(rate).to(beGreaterThan(0.75), description: "Expected >75% rejection, got \(Int(rate * 100))%")
                }
            }

            // MARK: - Test 6: Edge Cases

            context("with short trajectories") {
                it("should handle gracefully without crashing") {
                    let trajectory = [0.70, 0.75, 0.78]
                    let evidence = ConvergenceEvidence(trajectory: trajectory)

                    expect(evidence.coefficientOfVariation.isNaN).to(beFalse())
                    expect(evidence.convergenceProbability.isNaN).to(beFalse())
                }
            }

            // MARK: - Test 7: Already Excellent

            context("with already excellent trajectories") {
                it("should detect immediate convergence in >90% of cases") {
                    var detected = 0
                    let samples = 200

                    for _ in 0..<samples {
                        let traj = Self.generateAlreadyExcellent()
                        let evidence = ConvergenceEvidence(trajectory: traj)

                        if evidence.showsStrongConvergence || evidence.showsModerateConvergence {
                            detected += 1
                        }
                    }

                    let rate = Double(detected) / Double(samples)
                    expect(rate).to(beGreaterThan(0.90), description: "Expected >90% immediate convergence, got \(Int(rate * 100))%")
                }
            }
        }
    }

    // MARK: - Trajectory Generators

    static func generateTypicalReasoning() -> [Double] {
        var trajectory: [Double] = []
        var current = 0.70
        let iterations = Int.random(in: 5...8)

        for _ in 0..<iterations {
            let improvement = Double.random(in: 0.02...0.08)
            let noise = Double.random(in: -0.03...0.03)
            current = min(0.98, max(0.5, current + improvement + noise))
            trajectory.append(current)
        }
        return trajectory
    }

    static func generateStuckReasoning() -> [Double] {
        var trajectory: [Double] = []
        let baseValue = Double.random(in: 0.65...0.75)

        for _ in 0...Int.random(in: 6...10) {
            let noise = Double.random(in: -0.05...0.05)
            trajectory.append(min(0.95, max(0.5, baseValue + noise)))
        }
        return trajectory
    }

    static func generateBreakthroughReasoning() -> [Double] {
        var trajectory: [Double] = []
        let startValue = 0.60

        for i in 0..<3 {
            let noise = Double.random(in: -0.02...0.02)
            trajectory.append(startValue + Double(i) * 0.03 + noise)
        }

        trajectory.append(0.85 + Double.random(in: -0.03...0.03))

        for _ in 0..<2 {
            let noise = Double.random(in: -0.02...0.02)
            trajectory.append(0.90 + noise)
        }

        return trajectory
    }

    static func generateChaoticReasoning() -> [Double] {
        var trajectory: [Double] = []
        var current = 0.70

        for _ in 0..<8 {
            let change = Double.random(in: -0.15...0.15)
            current = min(0.95, max(0.50, current + change))
            trajectory.append(current)
        }
        return trajectory
    }

    static func generateRegressingReasoning() -> [Double] {
        var trajectory: [Double] = []
        var current = 0.80

        for _ in 0..<6 {
            let decline = Double.random(in: 0.02...0.06)
            let noise = Double.random(in: -0.02...0.02)
            current = max(0.50, current - decline + noise)
            trajectory.append(current)
        }
        return trajectory
    }

    static func generateAlreadyExcellent() -> [Double] {
        var trajectory: [Double] = []
        for _ in 0..<5 {
            let noise = Double.random(in: -0.01...0.01)
            trajectory.append(min(0.99, max(0.90, 0.95 + noise)))
        }
        return trajectory
    }
}

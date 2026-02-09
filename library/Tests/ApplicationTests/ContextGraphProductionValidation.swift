import AIPRDOrchestrationEngine
import AIPRDRAGEngine
import AIPRDSharedUtilities
import XCTest
@testable import Application
@testable import Domain

/// Production validation for ContextGraphTracker
/// Tests with 1M DIFFERENT random scenarios to validate algorithm correctness
final class ContextGraphProductionValidation: XCTestCase {

    // MARK: - Configuration (All Parameterizable - No Hardcoded Values)

    /// Sample count per validation run
    /// Default: 1,000,000 (comprehensive graph validation)
    /// Usage: VALIDATION_SAMPLES=100 swift test --filter ContextGraphProductionValidation (quick)
    private var productionSamples: Int {
        ProcessInfo.processInfo.environment["VALIDATION_SAMPLES"]
            .flatMap(Int.init) ?? 1_000_000
    }

    /// Number of independent runs for stability testing
    /// Default: 5 (statistical recommendation for 95% CI)
    /// Usage: STABILITY_RUNS=10 swift test --filter ContextGraphProductionValidation
    private var stabilityRuns: Int {
        ProcessInfo.processInfo.environment["STABILITY_RUNS"]
            .flatMap(Int.init) ?? 5
    }

    /// Maximum acceptable variance across runs (coefficient of variation)
    /// Default: 0.005 (0.5% - industry standard for stable algorithms)
    /// Usage: MAX_VARIANCE=0.01 swift test --filter ContextGraphProductionValidation
    private var maxVarianceAcrossRuns: Double {
        ProcessInfo.processInfo.environment["MAX_VARIANCE"]
            .flatMap(Double.init) ?? 0.005
    }

    /// Minimum acceptable correctness rate for cycle detection (95% CI lower bound)
    /// Default: 0.999 (99.9% - strict requirement for graph algorithms)
    /// Usage: TARGET_CORRECTNESS=0.995 swift test --filter ContextGraphProductionValidation
    private var targetCorrectnessRate: Double {
        ProcessInfo.processInfo.environment["TARGET_CORRECTNESS"]
            .flatMap(Double.init) ?? 0.999
    }

    /// Maximum acceptable mean time per validation run (seconds)
    /// Default: 60.0 (reasonable for 1M graph operations)
    /// Usage: MAX_RUN_TIME=120.0 swift test --filter ContextGraphProductionValidation
    private var maxRunTime: Double {
        ProcessInfo.processInfo.environment["MAX_RUN_TIME"]
            .flatMap(Double.init) ?? 60.0
    }

    // MARK: - Production Test: Acyclic Graphs (No False Positives)

    func testCycleDetection_acyclicGraphs_1M_samples() async throws {
        let result = await runStatisticalValidation(
            name: "Cycle Detection - Acyclic Graphs",
            generator: generateRandomAcyclicGraph,
            validator: { graph in
                await self.validateNoCycles(graph: graph)
            }
        )

        XCTAssertTrue(result.passed, result.failureMessage)
    }

    // MARK: - Production Test: Cyclic Graphs (No False Negatives)

    func testCycleDetection_cyclicGraphs_1M_samples() async throws {
        let result = await runStatisticalValidation(
            name: "Cycle Detection - Cyclic Graphs",
            generator: generateRandomCyclicGraph,
            validator: { graph in
                await self.validateHasCycles(graph: graph)
            }
        )

        XCTAssertTrue(result.passed, result.failureMessage)
    }

    // MARK: - Test Scenario Structure

    private struct GraphScenario {
        let nodes: [ContextNode]
        let edges: [(from: UUID, to: UUID)]
        let hasCycle: Bool
    }

    // MARK: - Random Graph Generators (Creates DIFFERENT graph each call)

    private func generateRandomAcyclicGraph() -> GraphScenario {
        // Random size: 3-15 nodes
        let nodeCount = Int.random(in: 3...15)
        var nodes: [ContextNode] = []

        // Create nodes
        for i in 0..<nodeCount {
            let node = ContextNode(
                type: .thought(thoughtType: .observation),
                content: "Node \(i)"
            )
            nodes.append(node)
        }

        // Create edges ensuring acyclic (DAG): only forward edges
        var edges: [(UUID, UUID)] = []
        let edgeDensity = Double.random(in: 0.2...0.6)  // Random density

        for i in 0..<nodeCount {
            for j in (i+1)..<nodeCount {  // Only forward edges (guarantees acyclic)
                if Double.random(in: 0...1) < edgeDensity {
                    edges.append((nodes[i].id, nodes[j].id))
                }
            }
        }

        return GraphScenario(nodes: nodes, edges: edges, hasCycle: false)
    }

    private func generateRandomCyclicGraph() -> GraphScenario {
        // Random size: 3-15 nodes
        let nodeCount = Int.random(in: 3...15)
        var nodes: [ContextNode] = []

        // Create nodes
        for i in 0..<nodeCount {
            let node = ContextNode(
                type: .thought(thoughtType: .observation),
                content: "Node \(i)"
            )
            nodes.append(node)
        }

        // Create edges with guaranteed cycle
        var edges: [(UUID, UUID)] = []

        // First, create a cycle: random length 3 to min(nodeCount, 10)
        let cycleLength = Int.random(in: 3...min(nodeCount, 10))
        let cycleNodes = nodes.prefix(cycleLength).shuffled()

        // Create cycle edges
        for i in 0..<cycleLength {
            let from = cycleNodes[i]
            let to = cycleNodes[(i + 1) % cycleLength]
            edges.append((from.id, to.id))
        }

        // Add random extra edges (may create more cycles)
        let extraEdgeCount = Int.random(in: 0...nodeCount)
        for _ in 0..<extraEdgeCount {
            let from = nodes.randomElement()!
            let to = nodes.randomElement()!
            if from.id != to.id {  // No self-loops in this test
                edges.append((from.id, to.id))
            }
        }

        return GraphScenario(nodes: nodes, edges: edges, hasCycle: true)
    }

    // MARK: - Validators (Test REAL implementation)

    private func validateNoCycles(graph: GraphScenario) async -> Bool {
        let tracker = ContextGraphTracker()

        // Build graph
        for node in graph.nodes {
            await tracker.addNode(node)
        }

        for (from, to) in graph.edges {
            await tracker.link(from: from, to: to, relationship: .dependsOn)
        }

        // Check every edge - NONE should create a cycle in acyclic graph
        for (from, to) in graph.edges {
            let hasCycle = await tracker.hasCircularDependency(from: from, to: to)
            if hasCycle {
                return false  // FALSE POSITIVE - detected cycle in acyclic graph
            }
        }

        return true  // Correct - no cycles detected
    }

    private func validateHasCycles(graph: GraphScenario) async -> Bool {
        let tracker = ContextGraphTracker()

        // Build graph
        for node in graph.nodes {
            await tracker.addNode(node)
        }

        for (from, to) in graph.edges {
            await tracker.link(from: from, to: to, relationship: .dependsOn)
        }

        // At least ONE edge should detect a cycle
        for (from, to) in graph.edges {
            let hasCycle = await tracker.hasCircularDependency(from: from, to: to)
            if hasCycle {
                return true  // Correct - cycle detected
            }
        }

        return false  // FALSE NEGATIVE - failed to detect cycle
    }

    // MARK: - Statistical Validation Framework (Same as HybridSearch)

    private struct ValidationResult {
        let passed: Bool
        let failureMessage: String
        let mean: Double
        let ci95Lower: Double
        let ci95Upper: Double
        let performanceNs: Double
        let runsVariance: Double
    }

    private func runStatisticalValidation<T>(
        name: String,
        generator: @escaping () -> T,
        validator: @escaping (T) async -> Bool
    ) async -> ValidationResult {

        print("\n" + String(repeating: "=", count: 80))
        print("🔬 PRODUCTION VALIDATION: \(name)")
        print(String(repeating: "=", count: 80))
        print("Target correctness: ≥\(Int(targetCorrectnessRate * 100))% (configurable via TARGET_CORRECTNESS)")
        print("Samples per run: \(productionSamples.formatted()) (configurable via VALIDATION_SAMPLES)")
        print("Stability runs: \(stabilityRuns) (configurable via STABILITY_RUNS)")
        print("Max variance: \(String(format: "%.2f", maxVarianceAcrossRuns * 100))% (configurable via MAX_VARIANCE)")
        print("Max run time: \(String(format: "%.0f", maxRunTime))s (configurable via MAX_RUN_TIME)")

        var rates: [Double] = []
        var performanceMeasurements: [Double] = []

        for run in 1...stabilityRuns {
            print("\n📊 Run \(run)/\(stabilityRuns)...")

            let startTime = Date()
            var correctCount = 0

            for i in 0..<productionSamples {
                let scenario = generator()  // NEW random scenario each iteration

                if await validator(scenario) {
                    correctCount += 1
                }

                if (i + 1) % 100_000 == 0 {
                    let progress = Double(i + 1) / Double(productionSamples) * 100
                    print("  [\(String(format: "%.0f", progress))%] \(i + 1) samples processed...")
                }
            }

            let elapsed = Date().timeIntervalSince(startTime)
            let rate = Double(correctCount) / Double(productionSamples)

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

        let standardError = stdDev / sqrt(Double(rates.count))
        let ci95Margin = 1.96 * standardError
        let ci95Lower = mean - ci95Margin
        let ci95Upper = mean + ci95Margin

        let runsVariance = stdDev / mean

        let avgPerformance = performanceMeasurements.reduce(0.0, +) / Double(performanceMeasurements.count)
        let avgThroughput = Double(productionSamples) / avgPerformance
        let performanceAcceptable = avgPerformance < maxRunTime

        print("\n" + String(repeating: "-", count: 80))
        print("📈 STATISTICAL SUMMARY")
        print(String(repeating: "-", count: 80))
        print("Mean rate:        \(String(format: "%.4f", mean)) (\(Int(mean * 100))%)")
        print("Std deviation:    \(String(format: "%.4f", stdDev))")
        print("95% CI:           [\(String(format: "%.4f", ci95Lower)), \(String(format: "%.4f", ci95Upper))]")
        print("Runs variance:    \(String(format: "%.2f", runsVariance * 100))%")
        print("Avg performance:  \(String(format: "%.2f", avgPerformance))s")
        print("Avg throughput:   \(String(format: "%.0f", avgThroughput)) samples/sec")

        let targetMet = ci95Lower > targetCorrectnessRate
        let stabilityMet = runsVariance < maxVarianceAcrossRuns
        let performanceMet = performanceAcceptable

        print("\n" + String(repeating: "-", count: 80))
        print("✅ VALIDATION CHECKS")
        print(String(repeating: "-", count: 80))
        print("Target met (CI > \(Int(targetCorrectnessRate * 100))%):  \(targetMet ? "✅ PASS" : "❌ FAIL")")
        print("Stability met (<\(String(format: "%.1f", maxVarianceAcrossRuns * 100))%):   \(stabilityMet ? "✅ PASS" : "❌ FAIL")")
        print("Performance met (<\(String(format: "%.0f", maxRunTime))s):  \(performanceMet ? "✅ PASS" : "❌ FAIL")")

        let allPassed = targetMet && stabilityMet && performanceMet

        if allPassed {
            print("\n🎉 VALIDATION PASSED")
        } else {
            print("\n❌ VALIDATION FAILED - IMPLEMENTATION HAS BUGS")
        }
        print(String(repeating: "=", count: 80) + "\n")

        let failureMessage = """
        \(name) validation failed - IMPLEMENTATION NEEDS FIXING:
          Mean rate: \(String(format: "%.4f", mean)) (\(Int(mean * 100))%),
          95% CI: [\(String(format: "%.4f", ci95Lower)), \(String(format: "%.4f", ci95Upper))]]
          Target: \(String(format: "%.4f", targetCorrectnessRate)) (\(Int(targetCorrectnessRate * 100))%)
          Runs variance: \(String(format: "%.2f", runsVariance * 100))%
          Performance: \(String(format: "%.2f", avgPerformance))s
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

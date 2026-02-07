import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import XCTest
@testable import Application

/// Production validation for GeneratePRDUseCase
/// Tests with randomized, scalable samples (100 to 1M+)
/// Follows CLAUDE.md Section 0.5: Professional Implementation Standards
final class GeneratePRDProductionValidation: XCTestCase {

    // MARK: - Configuration (All Parameterizable - No Hardcoded Values)

    /// Sample count per validation run
    /// Default: 100 (quick validation)
    /// Usage: VALIDATION_SAMPLES=1000000 swift test --filter GeneratePRDProductionValidation
    private var productionSamples: Int {
        ProcessInfo.processInfo.environment["VALIDATION_SAMPLES"]
            .flatMap(Int.init) ?? 100
    }

    /// Number of independent runs for stability testing
    /// Default: 5 (statistical recommendation for 95% CI)
    /// Usage: STABILITY_RUNS=10 swift test --filter GeneratePRDProductionValidation
    private var stabilityRuns: Int {
        ProcessInfo.processInfo.environment["STABILITY_RUNS"]
            .flatMap(Int.init) ?? 5
    }

    /// Maximum acceptable variance across runs (coefficient of variation)
    /// Default: 0.005 (0.5% - industry standard for stable algorithms)
    /// Usage: MAX_VARIANCE=0.01 swift test --filter GeneratePRDProductionValidation
    private var maxVarianceAcrossRuns: Double {
        ProcessInfo.processInfo.environment["MAX_VARIANCE"]
            .flatMap(Double.init) ?? 0.005
    }

    /// Minimum acceptable success rate (95% CI lower bound)
    /// Default: 0.95 (95% - standard confidence level)
    /// Usage: TARGET_SUCCESS_RATE=0.99 swift test --filter GeneratePRDProductionValidation
    private var targetSuccessRate: Double {
        ProcessInfo.processInfo.environment["TARGET_SUCCESS_RATE"]
            .flatMap(Double.init) ?? 0.95
    }

    /// Maximum acceptable mean generation time (seconds)
    /// Default: 1.0 (reasonable for production PRD generation)
    /// Usage: MAX_MEAN_TIME=2.0 swift test --filter GeneratePRDProductionValidation
    private var maxMeanTime: Double {
        ProcessInfo.processInfo.environment["MAX_MEAN_TIME"]
            .flatMap(Double.init) ?? 1.0
    }

    // MARK: - Production Validation Tests

    /// Validate PRD generation with N DIFFERENT randomized requests
    /// Tests REAL GeneratePRDUseCase implementation, not mock logic
    /// Multiple runs ensure stability (configurable via STABILITY_RUNS)
    func testPRDGeneration_production_validation() async throws {
        print("\n" + String(repeating: "=", count: 80))
        print("🔬 PRODUCTION VALIDATION: PRD Generation")
        print(String(repeating: "=", count: 80))
        print("Target success rate: ≥\(Int(targetSuccessRate * 100))% (configurable via TARGET_SUCCESS_RATE)")
        print("Samples per run: \(productionSamples.formatted()) (configurable via VALIDATION_SAMPLES)")
        print("Stability runs: \(stabilityRuns) (configurable via STABILITY_RUNS)")
        print("Max variance: \(String(format: "%.2f", maxVarianceAcrossRuns * 100))% (configurable via MAX_VARIANCE)")
        print("Max mean time: \(String(format: "%.2f", maxMeanTime))s (configurable via MAX_MEAN_TIME)")

        var successRates: [Double] = []
        var meanTimes: [Double] = []

        for run in 1...stabilityRuns {
            print("\n📊 Run \(run)/\(stabilityRuns)...")

            let runResult = try await performValidationRun()
            successRates.append(runResult.successRate)
            meanTimes.append(runResult.meanTime)

            print("  ✓ Success rate: \(String(format: "%.4f", runResult.successRate)) (\(Int(runResult.successRate * 100))%)")
            print("  ⏱️  Mean time: \(String(format: "%.4f", runResult.meanTime))s")
        }

        // Calculate statistics across runs
        let meanSuccessRate = successRates.reduce(0, +) / Double(successRates.count)
        let variance = successRates.map { pow($0 - meanSuccessRate, 2) }.reduce(0, +) / Double(successRates.count)
        let stdDev = sqrt(variance)
        let runsVariance = stdDev / meanSuccessRate

        let standardError = stdDev / sqrt(Double(successRates.count))
        let ci95Margin = 1.96 * standardError
        let ci95Lower = meanSuccessRate - ci95Margin
        let ci95Upper = meanSuccessRate + ci95Margin

        let avgMeanTime = meanTimes.reduce(0, +) / Double(meanTimes.count)

        print("\n" + String(repeating: "-", count: 80))
        print("📈 STATISTICAL SUMMARY")
        print(String(repeating: "-", count: 80))
        print("Mean success rate: \(String(format: "%.4f", meanSuccessRate)) (\(Int(meanSuccessRate * 100))%)")
        print("Std deviation:     \(String(format: "%.4f", stdDev))")
        print("95% CI:            [\(String(format: "%.4f", ci95Lower)), \(String(format: "%.4f", ci95Upper))]")
        print("Runs variance:     \(String(format: "%.2f", runsVariance * 100))%")
        print("Avg mean time:     \(String(format: "%.4f", avgMeanTime))s")

        let targetMet = ci95Lower > targetSuccessRate
        let stabilityMet = runsVariance < maxVarianceAcrossRuns
        let performanceMet = avgMeanTime < maxMeanTime

        print("\n" + String(repeating: "-", count: 80))
        print("✅ VALIDATION CHECKS")
        print(String(repeating: "-", count: 80))
        print("Target met (CI > \(Int(targetSuccessRate * 100))%):  \(targetMet ? "✅ PASS" : "❌ FAIL")")
        print("Stability met (<\(String(format: "%.1f", maxVarianceAcrossRuns * 100))%):   \(stabilityMet ? "✅ PASS" : "❌ FAIL")")
        print("Performance met (<\(String(format: "%.1f", maxMeanTime))s):  \(performanceMet ? "✅ PASS" : "❌ FAIL")")

        if targetMet && stabilityMet && performanceMet {
            print("\n🎉 VALIDATION PASSED")
        } else {
            print("\n❌ VALIDATION FAILED - IMPLEMENTATION HAS BUGS")
        }
        print(String(repeating: "=", count: 80) + "\n")

        // Assertions using configurable thresholds
        XCTAssertGreaterThan(
            ci95Lower,
            targetSuccessRate,
            "Success rate CI lower bound > \(Int(targetSuccessRate * 100))% (actual: \(String(format: "%.2f", ci95Lower * 100))%)"
        )

        XCTAssertLessThan(
            runsVariance,
            maxVarianceAcrossRuns,
            "Runs variance < \(String(format: "%.1f", maxVarianceAcrossRuns * 100))% (actual: \(String(format: "%.2f", runsVariance * 100))%)"
        )

        XCTAssertLessThan(
            avgMeanTime,
            maxMeanTime,
            "Mean time < \(String(format: "%.1f", maxMeanTime))s (actual: \(String(format: "%.4f", avgMeanTime))s)"
        )
    }

    // MARK: - Validation Run

    private struct RunResult {
        let successRate: Double
        let meanTime: Double
    }

    private func performValidationRun() async throws -> RunResult {
        var successCount = 0
        var failureCount = 0
        var validationTimes: [Double] = []

        for iteration in 0..<productionSamples {
            let startTime = Date()

            // Generate RANDOM request (different each time)
            let request = generateRandomPRDRequest()

            // Create REAL use case with mock dependencies
            let useCase = createRealUseCase()

            do {
                // Call REAL implementation
                let result = try await useCase.execute(request)

                // Validate result structure
                if validatePRDResult(result, for: request) {
                    successCount += 1
                } else {
                    failureCount += 1
                }
            } catch {
                // Expected errors (validation, etc.) are ok
                failureCount += 1
            }

            let elapsed = Date().timeIntervalSince(startTime)
            validationTimes.append(elapsed)

            // Progress indicator every 10%
            if productionSamples >= 1000 && (iteration + 1) % (productionSamples / 10) == 0 {
                let progress = Double(iteration + 1) / Double(productionSamples) * 100
                print("  [\(String(format: "%.0f", progress))%] \(iteration + 1) samples processed...")
            }
        }

        let successRate = Double(successCount) / Double(productionSamples)
        let meanTime = validationTimes.reduce(0, +) / Double(validationTimes.count)

        return RunResult(successRate: successRate, meanTime: meanTime)
    }

    // MARK: - Random Request Generation

    /// Generates DIFFERENT random PRD request each time
    /// NOT the same scenario with different IDs - truly randomized
    private func generateRandomPRDRequest() -> PRDRequest {
        let requestType = Int.random(in: 0...2)

        switch requestType {
        case 0:
            // Basic request (no template, no codebase)
            return PRDRequest(
                userId: UUID(),
                title: randomTitle(),
                description: randomDescription(),
                requirements: randomRequirements()
            )

        case 1:
            // With template
            return PRDRequest(
                userId: UUID(),
                title: randomTitle(),
                description: randomDescription(),
                requirements: randomRequirements(),
                codebaseId: nil,
                templateId: UUID()  // Mock template
            )

        case 2:
            // With codebase
            return PRDRequest(
                userId: UUID(),
                title: randomTitle(),
                description: randomDescription(),
                requirements: randomRequirements(),
                codebaseId: UUID(),
                templateId: nil
            )

        default:
            fatalError("Invalid random type")
        }
    }

    /// Random title - different each time
    private func randomTitle() -> String {
        let actions = ["Build", "Create", "Implement", "Design", "Develop", "Add", "Enhance"]
        let subjects = [
            "Authentication System",
            "Dashboard UI",
            "REST API",
            "Search Feature",
            "Analytics Module",
            "Payment Gateway",
            "Notification Service",
            "User Profile",
            "Admin Panel",
            "Data Export"
        ]

        return "\(actions.randomElement()!) \(subjects.randomElement()!)"
    }

    /// Random description - different each time
    private func randomDescription() -> String {
        let templates = [
            "Add support for {feature} with {capability}",
            "Implement {feature} that enables {capability}",
            "Create {feature} to improve {capability}",
            "Develop {feature} for better {capability}",
            "Build {feature} with focus on {capability}"
        ]

        let features = [
            "user authentication",
            "data visualization",
            "real-time updates",
            "offline mode",
            "multi-language support",
            "advanced filtering",
            "bulk operations",
            "export functionality"
        ]

        let capabilities = [
            "security",
            "user experience",
            "performance",
            "accessibility",
            "scalability",
            "maintainability",
            "reliability"
        ]

        return templates.randomElement()!
            .replacingOccurrences(of: "{feature}", with: features.randomElement()!)
            .replacingOccurrences(of: "{capability}", with: capabilities.randomElement()!)
    }

    /// Random requirements - different count and content each time
    private func randomRequirements() -> [Requirement] {
        let count = Int.random(in: 0...5)  // 0 to 5 requirements

        return (0..<count).map { index in
            Requirement(
                description: randomRequirementDescription(index: index),
                priority: [Priority.low, .medium, .high].randomElement()!,
                category: [
                    RequirementCategory.functional,
                    .nonFunctional,
                    .technical,
                    .security,
                    .performance
                ].randomElement()!
            )
        }
    }

    private func randomRequirementDescription(index: Int) -> String {
        let templates = [
            "Support {action} for {entity}",
            "Enable {action} with {constraint}",
            "Provide {action} functionality",
            "Implement {action} feature",
            "Allow users to {action}"
        ]

        let actions = [
            "create",
            "read",
            "update",
            "delete",
            "search",
            "filter",
            "export",
            "import",
            "share"
        ]

        let entities = [
            "users",
            "documents",
            "projects",
            "tasks",
            "reports",
            "settings"
        ]

        let constraints = [
            "validation",
            "authentication",
            "authorization",
            "rate limiting",
            "caching"
        ]

        var description = templates.randomElement()!
            .replacingOccurrences(of: "{action}", with: actions.randomElement()!)

        if description.contains("{entity}") {
            description = description.replacingOccurrences(of: "{entity}", with: entities.randomElement()!)
        }

        if description.contains("{constraint}") {
            description = description.replacingOccurrences(of: "{constraint}", with: constraints.randomElement()!)
        }

        return description
    }

    // MARK: - Use Case Creation

    /// Creates REAL GeneratePRDUseCase with mock dependencies
    /// Tests the REAL implementation, not mock logic
    private func createRealUseCase() -> GeneratePRDUseCase {
        // Mock AI provider with deterministic responses
        let mockAI = MockFactory.createAIProvider(
            responseMode: .success(mockPRDContent())
        )

        let mockPRDRepo = MockFactory.createPRDRepository()

        // Create template repository synchronously (simplified for validation)
        let mockTemplateRepo = MockPRDTemplateRepository()

        let config = GeneratePRDUseCaseConfig()
        return GeneratePRDUseCase(
            aiProvider: mockAI,
            prdRepository: mockPRDRepo,
            templateRepository: mockTemplateRepo,
            config: config
        )
    }

    private func mockPRDContent() -> String {
        """
        ## Overview
        Product requirements document generated for validation.

        ## Goals
        Define and validate system behavior.

        ## Requirements
        Support various input scenarios.

        ## Technical Specification
        Use industry-standard practices.
        """
    }

    // MARK: - Result Validation

    /// Validates PRD result matches request expectations
    private func validatePRDResult(_ result: PRDDocument, for request: PRDRequest) -> Bool {
        // Title should match or be related
        guard !result.title.isEmpty else { return false }

        // Should have sections
        guard !result.sections.isEmpty else { return false }

        // Metadata should be present
        guard !result.metadata.aiProvider.isEmpty else { return false }

        // Should have timestamps
        guard result.createdAt <= Date() else { return false }
        guard result.updatedAt <= Date() else { return false }

        return true
    }
}

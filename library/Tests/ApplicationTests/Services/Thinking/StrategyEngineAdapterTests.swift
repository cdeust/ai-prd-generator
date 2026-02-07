import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import AIPRDStrategyEngine
import XCTest
@testable import Application

/// Tests for StrategyEngineAdapter integration
/// Verifies the research-weighted strategy engine is properly integrated
final class StrategyEngineAdapterTests: XCTestCase {

    // MARK: - Test: Adapter Initialization

    func testAdapter_initializesWithLicensedTier() async {
        let adapter = StrategyEngineAdapter(licenseTier: .licensed)

        let result = await adapter.selectStrategy(
            for: "Complex technical requirement",
            context: "Enterprise system",
            hasCodebase: false,
            hasMockups: false
        )

        // Licensed tier should get research-optimized strategies (Tier 1 preferred)
        XCTAssertFalse(result.isDegraded, "Licensed tier should not be degraded")
        XCTAssertGreaterThan(result.expectedImprovement, 0, "Should have expected improvement")
        XCTAssertNotNil(result.primary, "Should select a primary strategy")
    }

    func testAdapter_initializesWithFreeTier() async {
        let adapter = StrategyEngineAdapter(licenseTier: .free)

        let result = await adapter.selectStrategy(
            for: "Complex technical requirement",
            context: "Enterprise system",
            hasCodebase: false,
            hasMockups: false
        )

        // Free tier should get degraded strategies
        XCTAssertTrue(result.isDegraded, "Free tier should be degraded")
    }

    // MARK: - Test: Strategy Selection

    func testAdapter_selectsAppropriateStrategy_forComplexClaim() async {
        let adapter = StrategyEngineAdapter(licenseTier: .licensed)

        let result = await adapter.selectStrategy(
            for: "Design a multi-tenant authentication system with RBAC, SSO integration, and precise security requirements",
            context: "Enterprise security architecture",
            hasCodebase: true,
            hasMockups: false
        )

        // Complex claims should get Tier 1 strategies
        XCTAssertFalse(result.isDegraded)

        // Verify research citations are provided
        XCTAssertFalse(result.researchBasis.isEmpty, "Should have research basis for selection")

        // Should select from advanced strategies for complex claims
        let advancedStrategies: [ThinkingStrategy] = [
            .recursiveRefinement,
            .verifiedReasoning,
            .selfConsistency,
            .reflexion,
            .problemAnalysis,
            .react
        ]
        XCTAssertTrue(
            advancedStrategies.contains(result.primary),
            "Complex claim should select advanced strategy, got: \(result.primary)"
        )
    }

    func testAdapter_selectsAppropriateStrategy_forSimpleClaim() async {
        let adapter = StrategyEngineAdapter(licenseTier: .licensed)

        let result = await adapter.selectStrategy(
            for: "List the files",
            context: nil,
            hasCodebase: false,
            hasMockups: false
        )

        // Simple claims allow any strategy
        XCTAssertFalse(result.isDegraded)
        XCTAssertNotNil(result.primary)
    }

    // MARK: - Test: Strategy Mapping

    func testAdapter_mapsStrategyNamesToEnums() async {
        let adapter = StrategyEngineAdapter(licenseTier: .licensed)

        // Test mapping from enum to name
        let recursiveName = await adapter.mapToStrategyName(.recursiveRefinement)
        XCTAssertEqual(recursiveName, "recursive_refinement")

        let verifiedName = await adapter.mapToStrategyName(.verifiedReasoning)
        XCTAssertEqual(verifiedName, "verified_reasoning")

        let cotName = await adapter.mapToStrategyName(.chainOfThought)
        XCTAssertEqual(cotName, "chain_of_thought")
    }

    // MARK: - Test: Enforcement

    func testAdapter_preparesEnforcedPrompt() async {
        let adapter = StrategyEngineAdapter(licenseTier: .licensed)

        let prepared = await adapter.prepareEnforcedPrompt(
            for: "Design authentication system",
            context: "Security",
            hasCodebase: false,
            hasMockups: false,
            basePrompt: "Generate PRD for authentication"
        )

        // Enforced prompt should be longer than base prompt (guidance added)
        XCTAssertGreaterThan(
            prepared.promptContent.count,
            "Generate PRD for authentication".count,
            "Enforced prompt should include strategy guidance"
        )

        // Should have assignment
        XCTAssertFalse(prepared.assignment.required.isEmpty, "Should have required strategies")
    }
}

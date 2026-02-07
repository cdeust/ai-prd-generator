import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import AIPRDStrategyEngine
import Application
import Foundation

/// Factory for creating the Research-Weighted Strategy Engine
/// Single entry point for strategy selection and enforcement
///
/// **Integration with other engines:**
/// - VerificationEngine: Strategy selection for claim verification
/// - RAGEngine: Context-aware strategy adaptation
/// - MetaPromptingEngine: Strategy execution with enforced prompts
///
/// **License-Based Behavior:**
/// - Licensed tier: Full research-weighted selection (Tier 1-3 strategies)
/// - Free tier: Basic strategies only (Tier 4: chain_of_thought, zero_shot)
struct StrategyFactory: Sendable {
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    // MARK: - Primary Factory Method

    /// Create the Strategy Engine Adapter with license-based configuration
    /// - Returns: Full engine for licensed users, degraded for free tier
    func createStrategyEngineAdapter() -> StrategyEngineResult {
        let licenseTier = configuration.licenseTier

        let adapter: StrategyEngineAdapter
        if licenseTier == .licensed {
            adapter = StrategyEngineAdapter(productionLicenseTier: .licensed)
            print("✅ [StrategyFactory] Research-Weighted Strategy Engine loaded (Licensed)")
            print("   Research papers integrated: MIT, Stanford, Harvard, Anthropic, OpenAI, DeepSeek")
            print("   Strategy tiers: Tier 1-3 (research-optimal)")
            print("   Expected improvement: +18-74% vs basic strategies")
            return .full(adapter)
        } else {
            adapter = StrategyEngineAdapter(licenseTier: .free)
            print("⚠️ [StrategyFactory] Strategy Engine loaded (Free Tier)")
            print("   Available strategies: chain_of_thought, zero_shot")
            print("   Upgrade to Licensed for research-optimal strategies")
            return .degraded(adapter)
        }
    }

    /// Create strategy engine adapter with explicit license tier override
    /// Use for testing or specific license scenarios
    func createStrategyEngineAdapter(licenseTier: LicenseTier) -> StrategyEngineResult {
        let adapter: StrategyEngineAdapter
        if licenseTier == .licensed {
            adapter = StrategyEngineAdapter(productionLicenseTier: .licensed)
            return .full(adapter)
        } else {
            adapter = StrategyEngineAdapter(licenseTier: .free)
            return .degraded(adapter)
        }
    }

    /// Create degraded strategy engine (free tier)
    /// Use when explicit degraded mode is required
    func createDegradedStrategyEngine() -> StrategyEngineAdapter {
        print("⚠️ [StrategyFactory] Creating degraded strategy engine (Free Tier)")
        return StrategyEngineAdapter(licenseTier: .free)
    }

    /// Create production-optimized strategy engine
    /// Uses conservative settings for production environments
    func createProductionStrategyEngine() -> StrategyEngineAdapter {
        let licenseTier = configuration.licenseTier
        print("✅ [StrategyFactory] Creating production strategy engine")
        return StrategyEngineAdapter(productionLicenseTier: licenseTier)
    }
}

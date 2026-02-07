import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import AIPRDVerificationEngine
import Application
import AIPRDSharedUtilities
import Foundation
import InfrastructureCore

/// Factory for creating the Unified Verification Engine
/// Single entry point for ALL verification needs
/// Integrates all research papers into ONE adaptive system:
/// - CoVe (Meta) + Atomic Claim Decomposition
/// - Graph-Constrained Reasoning
/// - NLI Entailment
/// - Multi-Agent Debate
/// - Adaptive Stability Consensus
/// Following Single Responsibility: Only creates verification components
struct VerificationFactory {
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    // MARK: - Primary Factory Method

    /// Create the Unified Verification Engine with automatic fallback
    /// This is THE single entry point for all verification needs
    /// - Parameters:
    ///   - primaryProvider: Primary AI provider
    ///   - preferences: User preferences for quality/cost tradeoff (default: adaptive)
    /// - Returns: Unified engine or degraded fallback
    func createUnifiedEngine(
        primaryProvider: AIProviderPort,
        preferences: UnifiedVerificationEngine.UserPreferences = .default
    ) async -> VerificationEngineResult {
        do {
            let judges = try await createJudgeProviders()

            let engine = UnifiedVerificationEngine(
                primaryProvider: primaryProvider,
                judges: judges,
                preferences: preferences
            )

            print("✅ [VerificationFactory] Unified Verification Engine loaded")
            print("   Research papers integrated: CoVe, Atomic, Graph, NLI, Debate, AdaptiveKS")
            print("   Quality target: \(preferences.qualityTarget.rawValue)")
            print("   Judges: \(judges.count)")

            return .unified(engine)
        } catch {
            print("⚠️ [VerificationFactory] Unified Engine unavailable: \(error)")
            print("   Using degraded heuristic verification")
            return .degraded(DegradedVerificationService())
        }
    }

    /// Create unified engine with specific quality target
    func createUnifiedEngine(
        primaryProvider: AIProviderPort,
        qualityTarget: VerificationQualityTarget
    ) async -> VerificationEngineResult {
        let preferences: UnifiedVerificationEngine.UserPreferences
        switch qualityTarget {
        case .fast:
            preferences = .fast
        case .balanced:
            preferences = .default
        case .thorough:
            preferences = .thorough
        case .adaptive:
            preferences = .default
        }
        return await createUnifiedEngine(primaryProvider: primaryProvider, preferences: preferences)
    }

    /// Create degraded verification service (heuristic-based)
    /// Use when no judges are available or engine loading fails
    func createDegradedVerificationService() -> DegradedVerificationService {
        print("⚠️ [VerificationFactory] Creating degraded verification service")
        return DegradedVerificationService()
    }

    // MARK: - Judge Providers

    /// Create multiple AI provider judges for evaluation
    private func createJudgeProviders() async throws -> [AIProviderPort] {
        let providerFactory = AIProviderFactory()
        let isClaudeCode = ProcessInfo.processInfo.environment["CLAUDECODE"] == "1"
        printClaudeCodeDetection(isClaudeCode)

        var judges: [AIProviderPort] = []
        judges.append(contentsOf: await createClaudeJudge(factory: providerFactory, isClaudeCode: isClaudeCode))
        judges.append(contentsOf: await createAppleIntelligenceJudge(factory: providerFactory))
        judges.append(contentsOf: await createOpenAIJudge(factory: providerFactory))
        judges.append(contentsOf: await createGeminiJudge(factory: providerFactory))
        judges.append(contentsOf: await createOpenRouterJudge(factory: providerFactory))
        judges.append(contentsOf: await createBedrockJudge(factory: providerFactory))

        try validateAndLogJudges(judges)
        return judges
    }

    private func printClaudeCodeDetection(_ isClaudeCode: Bool) {
        print("🔍 [VerificationFactory] Creating judge providers...")
        guard isClaudeCode else { return }
        print("📱 [VerificationFactory] Running inside Claude Code (authenticated session)")
        print("   Claude evaluates naturally in conversation - no API call needed")
        print("   Using Apple Intelligence + OpenAI/Gemini for programmatic consensus")
    }

    private func createClaudeJudge(
        factory: AIProviderFactory,
        isClaudeCode: Bool
    ) async -> [AIProviderPort] {
        guard !isClaudeCode,
              let anthropicKey = configuration.anthropicKey,
              !anthropicKey.isEmpty else {
            return []
        }

        let config = AIProviderConfiguration(
            type: .anthropic,
            apiKey: anthropicKey,
            model: "claude-sonnet-4-5"
        )
        guard let provider = try? await factory.createProvider(from: config) else {
            return []
        }
        print("✅ [VerificationFactory] Claude judge added (claude-sonnet-4-5)")
        return [provider]
    }

    private func createAppleIntelligenceJudge(
        factory: AIProviderFactory
    ) async -> [AIProviderPort] {
        #if os(iOS) || os(macOS)
        guard #available(iOS 26.0, macOS 26.0, *) else {
            print("⚠️ [VerificationFactory] Apple Intelligence not available (requires macOS 26+ Tahoe)")
            return []
        }

        let config = AIProviderConfiguration(
            type: .appleFoundationModels,
            apiKey: nil,
            model: nil
        )
        guard let provider = try? await factory.createProvider(from: config) else {
            print("⚠️ [VerificationFactory] Apple Intelligence provider creation failed")
            return []
        }
        print("✅ [VerificationFactory] Apple Intelligence judge added (on-device)")
        return [provider]
        #else
        return []
        #endif
    }

    private func createOpenAIJudge(
        factory: AIProviderFactory
    ) async -> [AIProviderPort] {
        guard let openAIKey = configuration.openAIKey, !openAIKey.isEmpty else {
            print("⚠️ [VerificationFactory] No OpenAI API key configured")
            return []
        }

        let config = AIProviderConfiguration(
            type: .openAI,
            apiKey: openAIKey,
            model: "gpt-4o"
        )
        guard let provider = try? await factory.createProvider(from: config) else {
            return []
        }
        print("✅ [VerificationFactory] OpenAI judge added (gpt-4o)")
        return [provider]
    }

    private func createGeminiJudge(
        factory: AIProviderFactory
    ) async -> [AIProviderPort] {
        guard let geminiKey = configuration.geminiKey, !geminiKey.isEmpty else {
            print("⚠️ [VerificationFactory] No Gemini API key configured")
            return []
        }

        let config = AIProviderConfiguration(
            type: .gemini,
            apiKey: geminiKey,
            model: "gemini-2.5-pro"
        )
        guard let provider = try? await factory.createProvider(from: config) else {
            return []
        }
        print("✅ [VerificationFactory] Gemini judge added (gemini-2.5-pro)")
        return [provider]
    }

    private func createOpenRouterJudge(
        factory: AIProviderFactory
    ) async -> [AIProviderPort] {
        guard let openRouterKey = configuration.openRouterKey, !openRouterKey.isEmpty else {
            print("⚠️ [VerificationFactory] No OpenRouter API key configured")
            return []
        }

        let config = AIProviderConfiguration(
            type: .openRouter,
            apiKey: openRouterKey,
            model: "anthropic/claude-sonnet-4-5"
        )
        guard let provider = try? await factory.createProvider(from: config) else {
            return []
        }
        print("✅ [VerificationFactory] OpenRouter judge added (anthropic/claude-sonnet-4-5)")
        return [provider]
    }

    private func createBedrockJudge(
        factory: AIProviderFactory
    ) async -> [AIProviderPort] {
        guard let accessKeyId = configuration.bedrockAccessKeyId,
              let secretAccessKey = configuration.bedrockSecretAccessKey,
              !accessKeyId.isEmpty,
              !secretAccessKey.isEmpty else {
            print("⚠️ [VerificationFactory] No AWS Bedrock credentials configured")
            return []
        }

        let config = AIProviderConfiguration(
            type: .bedrock,
            apiKey: nil,
            model: "anthropic.claude-sonnet-4-5-20250929",
            region: configuration.bedrockRegion ?? "us-east-1",
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey
        )
        guard let provider = try? await factory.createProvider(from: config) else {
            return []
        }
        print("✅ [VerificationFactory] AWS Bedrock judge added (anthropic.claude-sonnet-4-5-20250929)")
        return [provider]
    }

    private func validateAndLogJudges(_ judges: [AIProviderPort]) throws {
        guard !judges.isEmpty else {
            print("❌ [VerificationFactory] NO judges available")
            print("   Set at least one of: ANTHROPIC_API_KEY, OPENAI_API_KEY, GEMINI_API_KEY")
            print("   Or use macOS 26+ for Apple Intelligence")
            throw AIProviderError.authenticationFailed
        }
        print("✅ [VerificationFactory] Created \(judges.count) judge(s) for verification")
        if judges.count >= 2 {
            print("   Multi-LLM consensus enabled with \(judges.count) diverse models")
        } else {
            print("   ⚠️  Only 1 judge available - consensus works best with 2+ judges")
        }
    }
}

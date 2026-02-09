import AIPRDOrchestrationEngine
import Foundation
import AIPRDSharedUtilities
import AIPRDSharedUtilities
import Application
import InfrastructureCore

/// Judge Selection Strategy
/// Selects available AI provider judges based on environment capabilities
/// Following Single Responsibility: Only handles judge availability detection
///
/// Environment-aware judge selection:
/// - Native macOS/iOS: Includes Apple Intelligence
/// - Docker/Linux: Excludes Apple Intelligence (unavailable)
/// - Graceful degradation: Works with any number of judges ≥ 1
public actor JudgeSelectionStrategy {
    // MARK: - Properties

    private let providerFactory: AIProviderFactory

    // MARK: - Initialization

    public init(providerFactory: AIProviderFactory = AIProviderFactory()) {
        self.providerFactory = providerFactory
    }

    // MARK: - Judge Selection

    /// Select available judges based on environment
    public func selectAvailableJudges(
        primaryProvider: AIProviderConfiguration,
        secondaryProviders: [AIProviderConfiguration]
    ) async throws -> [AIProviderPort] {
        var judges: [AIProviderPort] = []
        judges.append(contentsOf: await createPrimaryJudge(from: primaryProvider))
        judges.append(contentsOf: await createAppleIntelligenceJudge())
        judges.append(contentsOf: await createSecondaryJudges(from: secondaryProviders))
        guard !judges.isEmpty else {
            throw AIProviderError.invalidConfiguration("No judges available - check AI provider configuration")
        }
        return judges
    }

    private func createPrimaryJudge(
        from config: AIProviderConfiguration
    ) async -> [AIProviderPort] {
        guard let provider = try? await providerFactory.createProvider(from: config) else {
            return []
        }
        return [provider]
    }

    private func createAppleIntelligenceJudge() async -> [AIProviderPort] {
        #if os(macOS) || os(iOS)
        guard #available(macOS 26.0, iOS 26.0, *) else {
            return []
        }
        let config = AIProviderConfiguration(type: .appleFoundationModels)
        guard let provider = try? await providerFactory.createProvider(from: config) else {
            return []
        }
        return [provider]
        #else
        return []
        #endif
    }

    private func createSecondaryJudges(from configs: [AIProviderConfiguration]) async -> [AIProviderPort] {
        var judges: [AIProviderPort] = []
        for config in configs {
            if let provider = try? await providerFactory.createProvider(from: config) {
                judges.append(provider)
            }
        }
        return judges
    }

    /// Select available judges with historical performance awareness
    /// Prefers reliable judges based on historical data
    /// - Parameters:
    ///   - primaryProvider: Primary AI provider configuration
    ///   - secondaryProviders: Additional provider configurations
    ///   - judgeWeights: Historical judge performance weights
    /// - Returns: Array of available judges, sorted by reliability
    public func selectAvailableJudges(
        primaryProvider: AIProviderConfiguration,
        secondaryProviders: [AIProviderConfiguration],
        judgeWeights: [String: Double]
    ) async throws -> [AIProviderPort] {
        // Get all available judges
        var judges = try await selectAvailableJudges(
            primaryProvider: primaryProvider,
            secondaryProviders: secondaryProviders
        )

        // Sort judges by historical reliability
        judges.sort { judge1, judge2 in
            let weight1 = judgeWeights[judge1.providerName] ?? 1.0
            let weight2 = judgeWeights[judge2.providerName] ?? 1.0
            return weight1 > weight2
        }

        // Limit to top 4 judges for performance
        if judges.count > 4 {
            judges = Array(judges.prefix(4))
        }

        return judges
    }

    /// Check if Apple Intelligence is available in current environment
    /// - Returns: true if Apple Intelligence can be used, false otherwise
    public func isAppleIntelligenceAvailable() -> Bool {
        #if os(macOS) || os(iOS)
        if #available(macOS 26.0, iOS 26.0, *) {
            return true
        }
        #endif
        return false
    }

    /// Get provider name for a given configuration
    /// Used for logging and debugging
    /// - Parameter config: Provider configuration
    /// - Returns: Provider name or "Unknown"
    public func getProviderName(
        for config: AIProviderConfiguration
    ) -> String {
        switch config.type {
        case .openAI:
            return "OpenAI"
        case .anthropic:
            return "Anthropic"
        case .gemini:
            return "Gemini"
        case .appleFoundationModels:
            return "Apple Foundation Models"
        case .openRouter:
            return "OpenRouter"
        case .bedrock:
            return "AWS Bedrock"
        case .qwen:
            return "Qwen"
        case .zhipu:
            return "Zhipu"
        case .moonshot:
            return "Moonshot"
        case .minimax:
            return "MiniMax"
        case .deepseek:
            return "DeepSeek"
        }
    }
}

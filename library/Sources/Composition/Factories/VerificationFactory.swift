import Foundation
import Domain
import Application
import InfrastructureCore

/// Factory for creating verification services (Chain of Verification)
/// Assembles multi-judge evaluation system with consensus
/// Following Single Responsibility: Only creates verification components
struct VerificationFactory {
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    /// Create Chain of Verification service with multiple judges
    /// - Parameters:
    ///   - primaryProvider: Primary AI provider (for question generation)
    ///   - evidenceRepository: Repository for persisting verification evidence (optional)
    /// - Returns: Configured ChainOfVerificationService
    /// - Throws: AIProviderError if provider creation fails
    func createVerificationService(
        primaryProvider: AIProviderPort,
        evidenceRepository: VerificationEvidenceRepositoryPort? = nil
    ) async throws -> ChainOfVerificationService {
        let questionGenerator = VerificationQuestionGeneratorService(
            aiProvider: primaryProvider
        )

        let judges = try await createJudgeProviders()
        let judgeEvaluator = MultiJudgeEvaluationService(judges: judges)

        let consensusResolver = ConsensusResolverService()

        return ChainOfVerificationService(
            questionGenerator: questionGenerator,
            judgeEvaluator: judgeEvaluator,
            consensusResolver: consensusResolver
        )
    }

    /// Create multiple AI provider judges for evaluation
    /// Creates instances of available providers (OpenAI, Anthropic, Gemini, Apple Intelligence, OpenRouter, Bedrock)
    /// All judges are optional - uses whatever providers have API keys configured
    /// - Returns: Array of configured judge providers
    /// - Throws: AIProviderError if NO providers are available
    private func createJudgeProviders() async throws -> [AIProviderPort] {
        var judges: [AIProviderPort] = []
        let providerFactory = AIProviderFactory()
        let isClaudeCode = ProcessInfo.processInfo.environment["CLAUDECODE"] == "1"

        printClaudeCodeDetection(isClaudeCode)
        try await addClaudeJudge(to: &judges, factory: providerFactory, isClaudeCode: isClaudeCode)
        try await addAppleIntelligenceJudge(to: &judges, factory: providerFactory)
        try await addOpenAIJudge(to: &judges, factory: providerFactory)
        try await addGeminiJudge(to: &judges, factory: providerFactory)
        try await addOpenRouterJudge(to: &judges, factory: providerFactory)
        try await addBedrockJudge(to: &judges, factory: providerFactory)
        try validateAndLogJudges(judges)

        return judges
    }

    private func printClaudeCodeDetection(_ isClaudeCode: Bool) {
        print("🔍 [VerificationFactory] Creating judge providers...")
        if isClaudeCode {
            print("📱 [VerificationFactory] Running inside Claude Code (authenticated session)")
            print("   Claude evaluates naturally in conversation - no API call needed")
            print("   Using Apple Intelligence + OpenAI/Gemini for programmatic consensus")
        }
    }

    private func addClaudeJudge(
        to judges: inout [AIProviderPort],
        factory: AIProviderFactory,
        isClaudeCode: Bool
    ) async throws {
        guard !isClaudeCode, let anthropicKey = configuration.anthropicKey, !anthropicKey.isEmpty else { return }

        let anthropicConfig = AIProviderConfiguration(
            type: .anthropic,
            apiKey: anthropicKey,
            model: "claude-sonnet-4-5"
        )
        if let provider = try? await factory.createProvider(from: anthropicConfig) {
            judges.append(provider)
            print("✅ [VerificationFactory] Claude judge added (claude-sonnet-4-5)")
        }
    }

    private func addAppleIntelligenceJudge(
        to judges: inout [AIProviderPort],
        factory: AIProviderFactory
    ) async throws {
        #if os(iOS) || os(macOS)
        if #available(iOS 26.0, macOS 26.0, *) {
            let appleConfig = AIProviderConfiguration(
                type: .appleFoundationModels,
                apiKey: nil,
                model: nil
            )
            if let provider = try? await factory.createProvider(from: appleConfig) {
                judges.append(provider)
                print("✅ [VerificationFactory] Apple Intelligence judge added (on-device)")
            } else {
                print("⚠️ [VerificationFactory] Apple Intelligence provider creation failed")
            }
        } else {
            print("⚠️ [VerificationFactory] Apple Intelligence not available (requires macOS 26+ Tahoe)")
        }
        #endif
    }

    private func addOpenAIJudge(
        to judges: inout [AIProviderPort],
        factory: AIProviderFactory
    ) async throws {
        guard let openAIKey = configuration.openAIKey, !openAIKey.isEmpty else {
            print("⚠️ [VerificationFactory] No OpenAI API key configured")
            return
        }

        let config = AIProviderConfiguration(type: .openAI, apiKey: openAIKey, model: "gpt-4o")
        if let provider = try? await factory.createProvider(from: config) {
            judges.append(provider)
            print("✅ [VerificationFactory] OpenAI judge added (gpt-4o)")
        }
    }

    private func addGeminiJudge(
        to judges: inout [AIProviderPort],
        factory: AIProviderFactory
    ) async throws {
        guard let geminiKey = configuration.geminiKey, !geminiKey.isEmpty else {
            print("⚠️ [VerificationFactory] No Gemini API key configured")
            return
        }

        let config = AIProviderConfiguration(type: .gemini, apiKey: geminiKey, model: "gemini-2.5-pro")
        if let provider = try? await factory.createProvider(from: config) {
            judges.append(provider)
            print("✅ [VerificationFactory] Gemini judge added (gemini-2.5-pro)")
        }
    }

    private func addOpenRouterJudge(
        to judges: inout [AIProviderPort],
        factory: AIProviderFactory
    ) async throws {
        guard let openRouterKey = configuration.openRouterKey, !openRouterKey.isEmpty else {
            print("⚠️ [VerificationFactory] No OpenRouter API key configured")
            return
        }

        let config = AIProviderConfiguration(type: .openRouter, apiKey: openRouterKey, model: "anthropic/claude-sonnet-4-5")
        if let provider = try? await factory.createProvider(from: config) {
            judges.append(provider)
            print("✅ [VerificationFactory] OpenRouter judge added (anthropic/claude-sonnet-4-5)")
        }
    }

    private func addBedrockJudge(
        to judges: inout [AIProviderPort],
        factory: AIProviderFactory
    ) async throws {
        guard let accessKeyId = configuration.bedrockAccessKeyId,
              let secretAccessKey = configuration.bedrockSecretAccessKey,
              !accessKeyId.isEmpty, !secretAccessKey.isEmpty else {
            print("⚠️ [VerificationFactory] No AWS Bedrock credentials configured")
            return
        }

        let config = AIProviderConfiguration(
            type: .bedrock,
            apiKey: nil,
            model: "anthropic.claude-sonnet-4-5-20250929",
            region: configuration.bedrockRegion ?? "us-east-1",
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey
        )
        if let provider = try? await factory.createProvider(from: config) {
            judges.append(provider)
            print("✅ [VerificationFactory] AWS Bedrock judge added (anthropic.claude-sonnet-4-5-20250929)")
        }
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



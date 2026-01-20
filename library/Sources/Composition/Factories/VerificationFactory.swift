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

        print("🔍 [VerificationFactory] Creating judge providers...")

        #if os(iOS) || os(macOS)
        if #available(iOS 26.0, macOS 26.0, *) {
            let appleConfig = AIProviderConfiguration(
                type: .appleFoundationModels,
                apiKey: nil,
                model: nil
            )
            if let appleProvider = try? await providerFactory.createProvider(from: appleConfig) {
                judges.append(appleProvider)
                print("✅ [VerificationFactory] Apple Intelligence judge added")
            }
        } else {
            print("⚠️ [VerificationFactory] Apple Intelligence not available (requires iOS 26+/macOS 26+)")
        }
        #endif

        if let openAIKey = configuration.openAIKey, !openAIKey.isEmpty {
            let openAIConfig = AIProviderConfiguration(
                type: .openAI,
                apiKey: openAIKey,
                model: "gpt-4o"
            )
            if let openAIProvider = try? await providerFactory.createProvider(from: openAIConfig) {
                judges.append(openAIProvider)
                print("✅ [VerificationFactory] OpenAI judge added (gpt-4o)")
            }
        } else {
            print("⚠️ [VerificationFactory] No OpenAI API key configured")
        }

        if let anthropicKey = configuration.anthropicKey, !anthropicKey.isEmpty {
            let anthropicConfig = AIProviderConfiguration(
                type: .anthropic,
                apiKey: anthropicKey,
                model: "claude-sonnet-4-5"
            )
            if let anthropicProvider = try? await providerFactory.createProvider(from: anthropicConfig) {
                judges.append(anthropicProvider)
                print("✅ [VerificationFactory] Anthropic judge added (claude-sonnet-4-5)")
            }
        } else {
            print("⚠️ [VerificationFactory] No Anthropic API key configured")
        }

        if let geminiKey = configuration.geminiKey, !geminiKey.isEmpty {
            let geminiConfig = AIProviderConfiguration(
                type: .gemini,
                apiKey: geminiKey,
                model: "gemini-2.5-pro"
            )
            if let geminiProvider = try? await providerFactory.createProvider(from: geminiConfig) {
                judges.append(geminiProvider)
                print("✅ [VerificationFactory] Gemini judge added (gemini-2.5-pro)")
            }
        } else {
            print("⚠️ [VerificationFactory] No Gemini API key configured")
        }

        if let openRouterKey = configuration.openRouterKey, !openRouterKey.isEmpty {
            let openRouterConfig = AIProviderConfiguration(
                type: .openRouter,
                apiKey: openRouterKey,
                model: "anthropic/claude-sonnet-4-5"
            )
            if let openRouterProvider = try? await providerFactory.createProvider(from: openRouterConfig) {
                judges.append(openRouterProvider)
                print("✅ [VerificationFactory] OpenRouter judge added (anthropic/claude-sonnet-4-5)")
            }
        } else {
            print("⚠️ [VerificationFactory] No OpenRouter API key configured")
        }

        if let bedrockAccessKeyId = configuration.bedrockAccessKeyId,
           let bedrockSecretAccessKey = configuration.bedrockSecretAccessKey,
           !bedrockAccessKeyId.isEmpty,
           !bedrockSecretAccessKey.isEmpty {
            let bedrockConfig = AIProviderConfiguration(
                type: .bedrock,
                apiKey: nil,
                model: "anthropic.claude-sonnet-4-5-20250929",
                region: configuration.bedrockRegion ?? "us-east-1",
                accessKeyId: bedrockAccessKeyId,
                secretAccessKey: bedrockSecretAccessKey
            )
            if let bedrockProvider = try? await providerFactory.createProvider(from: bedrockConfig) {
                judges.append(bedrockProvider)
                print("✅ [VerificationFactory] AWS Bedrock judge added (anthropic.claude-sonnet-4-5-20250929)")
            }
        } else {
            print("⚠️ [VerificationFactory] No AWS Bedrock credentials configured")
        }

        guard !judges.isEmpty else {
            print("❌ [VerificationFactory] NO judges available - need at least one API key")
            throw AIProviderError.authenticationFailed
        }

        print("✅ [VerificationFactory] Created \(judges.count) judge(s) for verification")
        return judges
    }
}

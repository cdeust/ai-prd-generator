import AIPRDOrchestrationEngine
import AIPRDSharedUtilities
import AIPRDVisionEngine
import AIPRDVisionEngineApple
import Application
import Foundation
import InfrastructureCore

struct AIComponentsFactory {
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
        Self.registerFoundationModelsOnce()
    }

    private static let _registerOnce: Void = {
        #if canImport(FoundationModels)
        VisionAnalyzerFactory.registerFoundationModelsSupport()
        #endif
    }()

    private static func registerFoundationModelsOnce() {
        _ = _registerOnce
    }

    func createTokenizer(for provider: AIProviderType) throws -> TokenizerPort {
        switch provider {
        case .appleFoundationModels:
            return AppleTokenizer()
        case .openAI:
            return try OpenAITokenizer()
        case .anthropic:
            return try ClaudeTokenizer()
        case .gemini:
            return GeminiTokenizer()
        case .openRouter:
            return OpenRouterTokenizer()
        case .bedrock:
            return try BedrockTokenizer()
        case .qwen, .zhipu, .moonshot, .minimax, .deepseek:
            // Chinese providers use OpenAI-compatible tokenization
            return try OpenAITokenizer()
        }
    }

    func createVisionAnalyzer() -> VisionAnalysisPort? {
        switch configuration.aiProvider {
        case .appleFoundationModels:
            #if os(macOS) || os(iOS)
            return AppleVisionAnalyzer()
            #else
            return nil
            #endif
        case .openAI:
            guard let apiKey = configuration.aiAPIKey else { return nil }
            return OpenAIVisionAnalyzer(apiKey: apiKey)
        case .anthropic:
            guard let apiKey = configuration.aiAPIKey else { return nil }
            return AnthropicVisionAnalyzer(apiKey: apiKey)
        case .gemini:
            guard let apiKey = configuration.aiAPIKey else { return nil }
            return GeminiVisionAnalyzer(apiKey: apiKey)
        case .openRouter:
            guard let apiKey = configuration.openRouterKey else { return nil }
            return OpenAIVisionAnalyzer(apiKey: apiKey)
        case .bedrock:
            guard let accessKeyId = configuration.bedrockAccessKeyId,
                  let secretAccessKey = configuration.bedrockSecretAccessKey else {
                return nil
            }
            let region = configuration.bedrockRegion ?? "us-east-1"
            let modelId = configuration.aiModel ?? "anthropic.claude-3-5-sonnet-20241022-v2:0"
            return BedrockVisionAnalyzer(
                region: region,
                accessKeyId: accessKeyId,
                secretAccessKey: secretAccessKey,
                modelId: modelId
            )
        case .qwen:
            guard let apiKey = configuration.aiAPIKey else { return nil }
            let config = ChineseProviderConfig.qwen
            return QwenVisionAnalyzer(
                apiKey: apiKey,
                model: config.visionModel ?? "qwen3-vl-plus",
                baseURL: config.baseURL
            )
        case .zhipu:
            guard let apiKey = configuration.aiAPIKey else { return nil }
            let config = ChineseProviderConfig.zhipu
            return ZhipuVisionAnalyzer(
                apiKey: apiKey,
                model: config.visionModel ?? "glm-4.6v",
                baseURL: config.baseURL
            )
        case .minimax:
            guard let apiKey = configuration.aiAPIKey else { return nil }
            let config = ChineseProviderConfig.minimax
            return MiniMaxVisionAnalyzer(
                apiKey: apiKey,
                model: config.visionModel ?? "MiniMax-VL-01",
                baseURL: config.baseURL
            )
        case .deepseek:
            guard let apiKey = configuration.aiAPIKey else { return nil }
            let config = ChineseProviderConfig.deepseek
            return DeepSeekVisionAnalyzer(
                apiKey: apiKey,
                model: config.visionModel ?? "deepseek-chat",
                baseURL: config.baseURL
            )
        case .moonshot:
            guard let apiKey = configuration.aiAPIKey else { return nil }
            let config = ChineseProviderConfig.moonshot
            return QwenVisionAnalyzer(
                apiKey: apiKey,
                model: config.visionModel ?? "kimi-k2.5",
                baseURL: config.baseURL
            )
        }
    }

    func createVisionAnalyzerAsync() async -> VisionAnalysisPort? {
        switch configuration.aiProvider {
        case .appleFoundationModels:
            #if os(macOS) || os(iOS)
            let factory = VisionAnalyzerFactory()
            return await factory.createBestOnDeviceAnalyzerWithFallback(
                configuration: .default,
                onFallback: { _, _ in }
            )
            #else
            return nil
            #endif
        case .openAI:
            guard let apiKey = configuration.aiAPIKey else { return nil }
            return OpenAIVisionAnalyzer(apiKey: apiKey)
        case .anthropic:
            guard let apiKey = configuration.aiAPIKey else { return nil }
            return AnthropicVisionAnalyzer(apiKey: apiKey)
        case .gemini:
            guard let apiKey = configuration.aiAPIKey else { return nil }
            return GeminiVisionAnalyzer(apiKey: apiKey)
        case .openRouter:
            guard let apiKey = configuration.openRouterKey else { return nil }
            return OpenAIVisionAnalyzer(apiKey: apiKey)
        case .bedrock:
            guard let accessKeyId = configuration.bedrockAccessKeyId,
                  let secretAccessKey = configuration.bedrockSecretAccessKey else {
                return nil
            }
            let region = configuration.bedrockRegion ?? "us-east-1"
            let modelId = configuration.aiModel ?? "anthropic.claude-3-5-sonnet-20241022-v2:0"
            return BedrockVisionAnalyzer(
                region: region,
                accessKeyId: accessKeyId,
                secretAccessKey: secretAccessKey,
                modelId: modelId
            )
        case .qwen:
            guard let apiKey = configuration.aiAPIKey else { return nil }
            let config = ChineseProviderConfig.qwen
            return QwenVisionAnalyzer(
                apiKey: apiKey,
                model: config.visionModel ?? "qwen3-vl-plus",
                baseURL: config.baseURL
            )
        case .zhipu:
            guard let apiKey = configuration.aiAPIKey else { return nil }
            let config = ChineseProviderConfig.zhipu
            return ZhipuVisionAnalyzer(
                apiKey: apiKey,
                model: config.visionModel ?? "glm-4.6v",
                baseURL: config.baseURL
            )
        case .minimax:
            guard let apiKey = configuration.aiAPIKey else { return nil }
            let config = ChineseProviderConfig.minimax
            return MiniMaxVisionAnalyzer(
                apiKey: apiKey,
                model: config.visionModel ?? "MiniMax-VL-01",
                baseURL: config.baseURL
            )
        case .deepseek:
            guard let apiKey = configuration.aiAPIKey else { return nil }
            let config = ChineseProviderConfig.deepseek
            return DeepSeekVisionAnalyzer(
                apiKey: apiKey,
                model: config.visionModel ?? "deepseek-chat",
                baseURL: config.baseURL
            )
        case .moonshot:
            guard let apiKey = configuration.aiAPIKey else { return nil }
            let config = ChineseProviderConfig.moonshot
            return QwenVisionAnalyzer(
                apiKey: apiKey,
                model: config.visionModel ?? "kimi-k2.5",
                baseURL: config.baseURL
            )
        }
    }

    func createCompressor(
        aiProvider: AIProviderPort,
        tokenizer: TokenizerPort
    ) -> AppleIntelligenceContextCompressor {
        let metaTokenCompressor = MetaTokenCompressor(tokenizer: tokenizer)
        return AppleIntelligenceContextCompressor(
            aiProvider: aiProvider,
            tokenizer: tokenizer,
            metaTokenCompressor: metaTokenCompressor
        )
    }

    func createPromptEngineeringService() -> PromptEngineeringService {
        // Licensed tier: Use sophisticated SectionPromptStrategy implementations
        // Free tier: Falls back to BasicPromptTemplates inside the service
        let strategies: [SectionType: SectionPromptStrategy] = [
            .overview: OverviewPromptTemplate(),
            .goals: GoalsPromptTemplate(),
            .requirements: RequirementsPromptTemplate(),
            .technicalSpecification: TechnicalSpecificationPromptTemplate(),
            .userStories: UserStoriesPromptTemplate(),
            .acceptanceCriteria: AcceptanceCriteriaPromptTemplate()
        ]

        return PromptEngineeringService(
            strategies: strategies,
            licenseTier: configuration.licenseTier
        )
    }

    func createInteractionHandler() -> UserInteractionPort? {
        return nil
    }
}

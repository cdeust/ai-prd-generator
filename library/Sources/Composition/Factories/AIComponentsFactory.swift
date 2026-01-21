import Foundation
import Domain
import Application
import InfrastructureCore

struct AIComponentsFactory {
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func createTokenizer(for provider: AIProviderType) -> TokenizerPort {
        switch provider {
        case .appleFoundationModels:
            return AppleTokenizer()
        case .openAI:
            return OpenAITokenizer()
        case .anthropic:
            return ClaudeTokenizer()
        case .gemini:
            return OpenAITokenizer()
        case .openRouter:
            // OpenRouter uses OpenAI-compatible format
            return OpenAITokenizer()
        case .bedrock:
            // Bedrock uses Claude tokenizer for Anthropic models
            return ClaudeTokenizer()
        }
    }

    // Vision analyzers: External providers work cross-platform, Apple-only on macOS/iOS
    func createVisionAnalyzer() -> VisionAnalysisPort? {
        switch configuration.aiProvider {
        case .appleFoundationModels:
            #if os(macOS) || os(iOS)
            if #available(iOS 15.0, macOS 12.0, *) {
                return AppleVisionAnalyzer()
            }
            return nil
            #else
            // Apple Intelligence not available on Linux
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
            // OpenRouter supports vision via compatible models (use OpenAI analyzer)
            guard let apiKey = configuration.openRouterKey else { return nil }
            return OpenAIVisionAnalyzer(apiKey: apiKey)
        case .bedrock:
            // TODO: Bedrock vision support requires BedrockVisionAnalyzer
            // Would use AWS Bedrock Converse API with vision-enabled models
            // Different from Anthropic direct API (uses IAM auth, different payload)
            // For now, vision not available with Bedrock provider
            return nil
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
        let strategies: [SectionType: SectionPromptStrategy] = [
            .overview: OverviewPromptTemplate(),
            .goals: GoalsPromptTemplate(),
            .requirements: RequirementsPromptTemplate(),
            .technicalSpecification: TechnicalSpecificationPromptTemplate(),
            .userStories: UserStoriesPromptTemplate(),
            .acceptanceCriteria: AcceptanceCriteriaPromptTemplate()
        ]

        return PromptEngineeringService(strategies: strategies)
    }

    func createInteractionHandler() -> UserInteractionPort? {
        return nil
    }
}

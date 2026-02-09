import AIPRDSharedUtilities
import Foundation

/// AI Provider Factory
/// Creates provider instances based on configuration
/// Following Single Responsibility: Only handles provider instantiation
/// Following Factory pattern for abstraction
/// API-based providers work on all platforms; only Apple Intelligence requires macOS 26+
public final class AIProviderFactory {
    // MARK: - Initialization

    public init() {}

    // MARK: - Factory Methods

    /// Create a provider based on configuration
    /// - Parameter config: Provider configuration
    /// - Returns: Configured AIProviderPort instance
    /// - Throws: AIProviderError if configuration is invalid
    public func createProvider(
        from config: AIProviderConfiguration
    ) async throws -> AIProviderPort {
        switch config.type {
        case .openAI:
            return try createOpenAIProvider(config: config)
        case .anthropic:
            return try createAnthropicProvider(config: config)
        case .gemini:
            return try createGeminiProvider(config: config)
        case .appleFoundationModels:
            return try createAppleFoundationModelsProvider(config: config)
        case .openRouter:
            return try createOpenRouterProvider(config: config)
        case .bedrock:
            return try await createBedrockProvider(config: config)
        case .qwen, .zhipu, .moonshot, .minimax, .deepseek:
            throw AIProviderError.generationFailed(
                "Chinese AI providers are available via VisionEngine only"
            )
        }
    }

    // MARK: - Private Factory Methods

    private func createOpenAIProvider(
        config: AIProviderConfiguration
    ) throws -> AIProviderPort {
        guard let apiKey = config.apiKey, !apiKey.isEmpty else {
            throw AIProviderError.authenticationFailed
        }

        let model = config.model ?? AIProviderConfiguration.defaultModel(for: .openAI)
        let baseURL = config.baseURL ?? AIProviderConfiguration.defaultBaseURL(for: .openAI)!

        return OpenAIProvider(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL
        )
    }

    private func createAnthropicProvider(
        config: AIProviderConfiguration
    ) throws -> AIProviderPort {
        guard let apiKey = config.apiKey, !apiKey.isEmpty else {
            throw AIProviderError.authenticationFailed
        }

        let model = config.model ?? AIProviderConfiguration.defaultModel(for: .anthropic)
        let baseURL = config.baseURL ?? AIProviderConfiguration.defaultBaseURL(for: .anthropic)!
        let apiVersion = config.apiVersion ?? AIProviderConfiguration.anthropicAPIVersion

        return AnthropicProvider(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL,
            apiVersion: apiVersion,
            maxOutputTokens: config.maxOutputTokens
        )
    }

    private func createGeminiProvider(
        config: AIProviderConfiguration
    ) throws -> AIProviderPort {
        guard let apiKey = config.apiKey, !apiKey.isEmpty else {
            throw AIProviderError.authenticationFailed
        }

        let model = config.model ?? AIProviderConfiguration.defaultModel(for: .gemini)
        let baseURL = config.baseURL ?? AIProviderConfiguration.defaultBaseURL(for: .gemini)!

        return GeminiProvider(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL
        )
    }

    private func createAppleFoundationModelsProvider(
        config: AIProviderConfiguration
    ) throws -> AIProviderPort {
        #if os(iOS) || os(macOS)
        if #available(iOS 26.0, macOS 26.0, *) {
            return try AppleFoundationModelsProvider(
                mode: .onDevice
            )
        } else {
            throw AIProviderError.generationFailed(
                "Apple Foundation Models requires iOS 18.0+ or macOS 15.0+"
            )
        }
        #else
        throw AIProviderError.generationFailed(
            "Apple Foundation Models only available on iOS/macOS"
        )
        #endif
    }

    private func createOpenRouterProvider(
        config: AIProviderConfiguration
    ) throws -> AIProviderPort {
        guard let apiKey = config.apiKey, !apiKey.isEmpty else {
            throw AIProviderError.authenticationFailed
        }

        let model = config.model ?? AIProviderConfiguration.defaultModel(for: .openRouter)
        let baseURL = config.baseURL ?? AIProviderConfiguration.defaultBaseURL(for: .openRouter)!

        return OpenRouterProvider(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL
        )
    }

    private func createBedrockProvider(
        config: AIProviderConfiguration
    ) async throws -> AIProviderPort {
        guard let region = config.region, !region.isEmpty else {
            throw AIProviderError.invalidConfiguration(
                "AWS region required for Bedrock"
            )
        }

        guard let accessKeyId = config.accessKeyId, !accessKeyId.isEmpty else {
            throw AIProviderError.invalidConfiguration(
                "AWS access key ID required for Bedrock"
            )
        }

        guard let secretAccessKey = config.secretAccessKey,
              !secretAccessKey.isEmpty else {
            throw AIProviderError.authenticationFailed
        }

        let model = config.model ?? AIProviderConfiguration.defaultModel(for: .bedrock)

        return try await BedrockProvider(
            region: region,
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey,
            modelId: model,
            maxOutputTokens: config.maxOutputTokens,
            reasoningTokensLow: config.reasoningTokensLow,
            reasoningTokensMedium: config.reasoningTokensMedium,
            reasoningTokensHigh: config.reasoningTokensHigh
        )
    }
}

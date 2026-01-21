import Foundation
import Domain

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
        }
    }

    // MARK: - Private Factory Methods

    private func createOpenAIProvider(
        config: AIProviderConfiguration
    ) throws -> AIProviderPort {
        guard let apiKey = config.apiKey, !apiKey.isEmpty else {
            throw AIProviderError.authenticationFailed
        }

        return OpenAIProvider(
            apiKey: apiKey,
            model: config.model ?? "gpt-5"
        )
    }

    private func createAnthropicProvider(
        config: AIProviderConfiguration
    ) throws -> AIProviderPort {
        guard let apiKey = config.apiKey, !apiKey.isEmpty else {
            throw AIProviderError.authenticationFailed
        }

        return AnthropicProvider(
            apiKey: apiKey,
            model: config.model ?? "claude-sonnet-4-5"
        )
    }

    private func createGeminiProvider(
        config: AIProviderConfiguration
    ) throws -> AIProviderPort {
        guard let apiKey = config.apiKey, !apiKey.isEmpty else {
            throw AIProviderError.authenticationFailed
        }

        return GeminiProvider(
            apiKey: apiKey,
            model: config.model ?? "gemini-2.5-pro"
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

        return OpenRouterProvider(
            apiKey: apiKey,
            model: config.model ?? "anthropic/claude-sonnet-4-5"
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

        return try await BedrockProvider(
            region: region,
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey,
            modelId: config.model ?? "anthropic.claude-sonnet-4-5-20250929"
        )
    }
}

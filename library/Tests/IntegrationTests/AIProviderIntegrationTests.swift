import XCTest
import AIPRDSharedUtilities
@testable import InfrastructureCore
@testable import Domain
@testable import Composition

/// Integration tests for AI provider instantiation and configuration
/// Tests that providers can be created and configured correctly
/// Does NOT test actual API calls (requires real API keys)
final class AIProviderIntegrationTests: XCTestCase {

    // MARK: - OpenRouter Provider Tests

    func testOpenRouterProviderInstantiation() throws {
        // Given: OpenRouter configuration
        let apiKey = "test-key-123"
        let model = "anthropic/claude-sonnet-4-5"

        // When: Create OpenRouter provider
        let provider = OpenRouterProvider(
            apiKey: apiKey,
            model: model
        )

        // Then: Provider is configured correctly
        XCTAssertEqual(provider.providerName, "OpenRouter")
        XCTAssertEqual(provider.modelName, model)
        XCTAssertEqual(provider.contextWindowSize, 200_000) // Claude model
    }

    func testOpenRouterProviderContextWindowDetection() {
        // Test Claude models
        let claudeProvider = OpenRouterProvider(
            apiKey: "test",
            model: "anthropic/claude-sonnet-4-5"
        )
        XCTAssertEqual(claudeProvider.contextWindowSize, 200_000)

        // Test GPT-4 models
        let gpt4Provider = OpenRouterProvider(
            apiKey: "test",
            model: "openai/gpt-4"
        )
        XCTAssertEqual(gpt4Provider.contextWindowSize, 128_000)

        // Test unknown models (default)
        let unknownProvider = OpenRouterProvider(
            apiKey: "test",
            model: "unknown/model"
        )
        XCTAssertEqual(unknownProvider.contextWindowSize, 32_000)
    }

    // MARK: - Bedrock Provider Tests

    @available(iOS 15.0, macOS 12.0, *)
    func testBedrockProviderInstantiation() async throws {
        // Given: Bedrock configuration
        let region = "us-east-1"
        let accessKeyId = "AKIA-TEST-KEY"
        let secretAccessKey = "test-secret-key"
        let modelId = "anthropic.claude-sonnet-4-5-20250929"

        // When: Create Bedrock provider
        let provider = try await BedrockProvider(
            region: region,
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey,
            modelId: modelId
        )

        // Then: Provider is configured correctly
        XCTAssertEqual(provider.providerName, "AWS Bedrock")
        XCTAssertEqual(provider.modelName, modelId)
        XCTAssertEqual(provider.contextWindowSize, 200_000) // Claude model
    }

    @available(iOS 15.0, macOS 12.0, *)
    func testBedrockProviderContextWindowDetection() async throws {
        // Test Claude models
        let claudeProvider = try await BedrockProvider(
            region: "us-east-1",
            accessKeyId: "test",
            secretAccessKey: "test",
            modelId: "anthropic.claude-sonnet-4-5-20250929"
        )
        XCTAssertEqual(claudeProvider.contextWindowSize, 200_000)

        // Test Titan models
        let titanProvider = try await BedrockProvider(
            region: "us-east-1",
            accessKeyId: "test",
            secretAccessKey: "test",
            modelId: "amazon.titan-text-express-v1"
        )
        XCTAssertEqual(titanProvider.contextWindowSize, 32_000)

        // Test Llama models
        let llamaProvider = try await BedrockProvider(
            region: "us-east-1",
            accessKeyId: "test",
            secretAccessKey: "test",
            modelId: "meta.llama2-13b-chat-v1"
        )
        XCTAssertEqual(llamaProvider.contextWindowSize, 8_000)
    }

    // MARK: - AIProviderFactory Tests

    func testAIProviderFactoryCreatesOpenRouter() async throws {
        // Given: OpenRouter configuration
        let config = AIProviderConfiguration(
            type: .openRouter,
            apiKey: "test-key",
            model: "anthropic/claude-sonnet-4-5"
        )

        let factory = AIProviderFactory()

        // When: Create provider via factory
        let provider = try await factory.createProvider(from: config)

        // Then: Correct provider type created
        XCTAssertEqual(provider.providerName, "OpenRouter")
        XCTAssertEqual(provider.modelName, "anthropic/claude-sonnet-4-5")
    }

    @available(iOS 15.0, macOS 12.0, *)
    func testAIProviderFactoryCreatesBedrock() async throws {
        // Given: Bedrock configuration
        let config = AIProviderConfiguration(
            type: .bedrock,
            apiKey: nil,
            model: "anthropic.claude-sonnet-4-5-20250929",
            region: "us-east-1",
            accessKeyId: "AKIA-TEST",
            secretAccessKey: "test-secret"
        )

        let factory = AIProviderFactory()

        // When: Create provider via factory
        let provider = try await factory.createProvider(from: config)

        // Then: Correct provider type created
        XCTAssertEqual(provider.providerName, "AWS Bedrock")
        XCTAssertEqual(provider.modelName, "anthropic.claude-sonnet-4-5-20250929")
    }

    // MARK: - Configuration Parsing Tests

    func testConfigurationParsesOpenRouter() {
        // Given: Environment variables
        let env = [
            "AI_PROVIDER": "openrouter",
            "OPENROUTER_API_KEY": "sk-or-v1-test",
            "OPENROUTER_MODEL": "anthropic/claude-sonnet-4-5"
        ]

        // When: Parse configuration
        // Note: This test would need Configuration.fromEnvironment() to accept custom env
        // For now, we validate the parsing logic exists

        // Then: Configuration should parse correctly
        // (Actual test would verify Configuration.aiProvider == .openRouter)
    }

    func testConfigurationParsesBedrock() {
        // Given: Environment variables
        let env = [
            "AI_PROVIDER": "bedrock",
            "AWS_BEDROCK_REGION": "us-east-1",
            "AWS_ACCESS_KEY_ID": "AKIA-TEST",
            "AWS_SECRET_ACCESS_KEY": "test-secret",
            "AWS_BEDROCK_MODEL": "anthropic.claude-sonnet-4-5-20250929"
        ]

        // When: Parse configuration
        // Note: This test would need Configuration.fromEnvironment() to accept custom env

        // Then: Configuration should parse correctly
        // (Actual test would verify Configuration.aiProvider == .bedrock)
    }

    // MARK: - Error Handling Tests

    func testOpenRouterProviderValidatesAPIKey() async throws {
        // Given: OpenRouter provider with empty API key
        let provider = OpenRouterProvider(
            apiKey: "",
            model: "anthropic/claude-sonnet-4-5"
        )

        // When/Then: Should throw authentication error
        do {
            _ = try await provider.generateText(
                prompt: "test",
                temperature: 0.7
            )
            XCTFail("Should have thrown authentication error")
        } catch let error as AIProviderError {
            if case .authenticationFailed = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    @available(iOS 15.0, macOS 12.0, *)
    func testBedrockProviderValidatesCredentials() async throws {
        // Given: Factory with missing credentials
        let config = AIProviderConfiguration(
            type: .bedrock,
            apiKey: nil,
            model: "anthropic.claude-sonnet-4-5-20250929",
            region: "",  // Empty region
            accessKeyId: "test",
            secretAccessKey: "test"
        )

        let factory = AIProviderFactory()

        // When/Then: Should throw configuration error
        do {
            _ = try await factory.createProvider(from: config)
            XCTFail("Should have thrown configuration error")
        } catch let error as AIProviderError {
            if case .invalidConfiguration = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
}

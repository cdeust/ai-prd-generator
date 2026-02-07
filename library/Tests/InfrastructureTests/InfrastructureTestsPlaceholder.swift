import AIPRDSharedUtilities
import XCTest

@testable import InfrastructureCore

/// Tests for Infrastructure layer core components
final class InfrastructureCoreTests: XCTestCase {

    // MARK: - AIProviderType Tests

    func testAIProviderTypeAllCases() {
        let allCases = AIProviderType.allCases
        XCTAssertFalse(allCases.isEmpty, "AIProviderType should have at least one case")
        XCTAssertTrue(allCases.contains(.anthropic), "Should include Anthropic provider")
        XCTAssertTrue(allCases.contains(.openAI), "Should include OpenAI provider")
        XCTAssertTrue(allCases.contains(.gemini), "Should include Gemini provider")
    }

    func testAIProviderTypeRawValues() {
        XCTAssertEqual(AIProviderType.anthropic.rawValue, "anthropic")
        XCTAssertEqual(AIProviderType.openAI.rawValue, "openai")
        XCTAssertEqual(AIProviderType.gemini.rawValue, "gemini")
        XCTAssertEqual(AIProviderType.bedrock.rawValue, "bedrock")
        XCTAssertEqual(AIProviderType.openRouter.rawValue, "openrouter")
    }

    func testAIProviderTypeFromRawValue() {
        XCTAssertEqual(AIProviderType(rawValue: "anthropic"), .anthropic)
        XCTAssertEqual(AIProviderType(rawValue: "openai"), .openAI)
        XCTAssertNil(AIProviderType(rawValue: "invalid"))
    }

    func testAIProviderTypeChineseProviders() {
        XCTAssertEqual(AIProviderType.qwen.rawValue, "qwen")
        XCTAssertEqual(AIProviderType.zhipu.rawValue, "zhipu")
        XCTAssertEqual(AIProviderType.moonshot.rawValue, "moonshot")
        XCTAssertEqual(AIProviderType.minimax.rawValue, "minimax")
        XCTAssertEqual(AIProviderType.deepseek.rawValue, "deepseek")
    }

    // MARK: - AIProviderConfiguration Tests

    func testAIProviderConfigurationDefaults() {
        let config = AIProviderConfiguration(type: .anthropic)
        XCTAssertEqual(config.type, .anthropic)
        XCTAssertNil(config.apiKey)
        XCTAssertNil(config.model)
        XCTAssertEqual(config.maxOutputTokens, 8192)
        XCTAssertEqual(config.reasoningTokensLow, 10_000)
        XCTAssertEqual(config.reasoningTokensMedium, 25_000)
        XCTAssertEqual(config.reasoningTokensHigh, 50_000)
    }

    func testAIProviderConfigurationCustomValues() {
        let config = AIProviderConfiguration(
            type: .openAI,
            apiKey: "test-key",
            model: "gpt-5.2",
            maxOutputTokens: 16384
        )
        XCTAssertEqual(config.type, .openAI)
        XCTAssertEqual(config.apiKey, "test-key")
        XCTAssertEqual(config.model, "gpt-5.2")
        XCTAssertEqual(config.maxOutputTokens, 16384)
    }

    func testAIProviderConfigurationDefaultModels() {
        // Test that default models are returned for each provider
        XCTAssertFalse(AIProviderConfiguration.defaultModel(for: .anthropic).isEmpty)
        XCTAssertFalse(AIProviderConfiguration.defaultModel(for: .openAI).isEmpty)
        XCTAssertFalse(AIProviderConfiguration.defaultModel(for: .gemini).isEmpty)
        XCTAssertFalse(AIProviderConfiguration.defaultModel(for: .bedrock).isEmpty)
        XCTAssertFalse(AIProviderConfiguration.defaultModel(for: .openRouter).isEmpty)
    }

    func testAIProviderConfigurationDefaultBaseURLs() {
        XCTAssertNotNil(AIProviderConfiguration.defaultBaseURL(for: .anthropic))
        XCTAssertNotNil(AIProviderConfiguration.defaultBaseURL(for: .openAI))
        XCTAssertNotNil(AIProviderConfiguration.defaultBaseURL(for: .gemini))
        XCTAssertNotNil(AIProviderConfiguration.defaultBaseURL(for: .openRouter))
    }

    // MARK: - ChunkingState Tests

    func testChunkingStateInitialization() {
        let state = ChunkingState()
        XCTAssertEqual(state.chunks.count, 0)
        XCTAssertEqual(state.currentChunk, "")
        XCTAssertEqual(state.currentStart, 0)
    }

    func testChunkingStateWithCurrentChunk() {
        let state = ChunkingState()
        let updated = state.withCurrentChunk("test content", start: 10)
        XCTAssertEqual(updated.currentChunk, "test content")
        XCTAssertEqual(updated.currentStart, 10)
    }

    func testChunkingStateWithAppendedChunk() {
        let state = ChunkingState().withCurrentChunk("first", start: 0)
        let updated = state.withAppendedChunk("second")
        XCTAssertTrue(updated.currentChunk.contains("first"))
        XCTAssertTrue(updated.currentChunk.contains("second"))
    }
}

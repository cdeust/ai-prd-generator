import Foundation

/// Port for AI text generation
/// Domain defines the interface, Infrastructure implements it
/// Following Dependency Inversion Principle
public protocol AIProviderPort: Sendable {
    /// Generate text from a prompt
    /// - Parameters:
    ///   - prompt: The input prompt
    ///   - temperature: Creativity level (0.0-1.0)
    ///   - extendedThinking: Enable extended thinking mode (50K token budget for Anthropic)
    /// - Returns: Generated text
    func generateText(
        prompt: String,
        temperature: Double,
        extendedThinking: Bool?
    ) async throws -> String

    /// Stream text generation (for real-time updates)
    /// - Parameters:
    ///   - prompt: The input prompt
    ///   - temperature: Creativity level
    ///   - extendedThinking: Enable extended thinking mode (50K token budget for Anthropic)
    /// - Returns: AsyncStream of text chunks
    func streamText(
        prompt: String,
        temperature: Double,
        extendedThinking: Bool?
    ) async throws -> AsyncStream<String>

    /// Get provider name
    var providerName: String { get }

    /// Get model name
    var modelName: String { get }

    /// Get context window size in tokens
    /// Different providers have different limits:
    /// - Apple Intelligence: 4,096 tokens
    /// - OpenAI GPT-4: 128,000 tokens
    /// - Anthropic Claude: 200,000 tokens
    /// - Gemini Pro: 128,000 tokens
    var contextWindowSize: Int { get }
}

// MARK: - Default Parameter Values
/// Protocol extension to provide default values for backward compatibility
public extension AIProviderPort {
    func generateText(
        prompt: String,
        temperature: Double
    ) async throws -> String {
        try await generateText(prompt: prompt, temperature: temperature, extendedThinking: true)
    }

    func streamText(
        prompt: String,
        temperature: Double
    ) async throws -> AsyncStream<String> {
        try await streamText(prompt: prompt, temperature: temperature, extendedThinking: true)
    }
}

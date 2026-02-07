import AIPRDSharedUtilities
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Anthropic AI Provider Implementation
/// Implements AIProviderPort using Anthropic's Messages API
@available(iOS 15.0, macOS 12.0, *)
public final class AnthropicProvider: AIProviderPort, PromptCachingProviderPort, Sendable {
    private let apiKey: String
    private let model: String
    private let baseURL: URL
    private let apiVersion: String
    private let requestBuilder: AnthropicRequestBuilder
    private let responseHandler: AnthropicResponseHandler

    /// Initialize Anthropic provider
    /// - Parameters:
    ///   - apiKey: Anthropic API key
    ///   - model: Model identifier (env: ANTHROPIC_MODEL, default: claude-sonnet-4-6-20260201)
    ///   - baseURL: API base URL (env: ANTHROPIC_BASE_URL)
    ///   - apiVersion: API version (env: ANTHROPIC_API_VERSION, default: 2025-01-01)
    ///   - maxOutputTokens: Maximum output tokens (env: LLM_MAX_OUTPUT_TOKENS, default: 8192)
    public init(
        apiKey: String,
        model: String = "claude-sonnet-4-6-20260201",
        baseURL: URL = URL(string: "https://api.anthropic.com/v1")!,
        apiVersion: String = "2025-01-01",
        maxOutputTokens: Int = 8192
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.apiVersion = apiVersion
        self.requestBuilder = AnthropicRequestBuilder(
            apiKey: apiKey,
            model: model,
            baseURL: baseURL,
            apiVersion: apiVersion,
            maxOutputTokens: maxOutputTokens
        )
        self.responseHandler = AnthropicResponseHandler()
    }

    public func generateText(
        prompt: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIProviderError.authenticationFailed
        }

        return try await performMessageCompletion(
            prompt: prompt,
            temperature: temperature,
            reasoningEffort: reasoningEffort
        )
    }

    public func streamText(
        prompt: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort
    ) async throws -> AsyncStream<String> {
        guard !apiKey.isEmpty else {
            throw AIProviderError.authenticationFailed
        }

        return try await performStreamingCompletion(
            prompt: prompt,
            temperature: temperature,
            reasoningEffort: reasoningEffort
        )
    }

    public var providerName: String { "Anthropic" }
    public var modelName: String { model }
    public var contextWindowSize: Int { 200_000 }

    public func generateTextWithCaching(
        cachedContext: String,
        prompt: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort,
        cacheTTL: CacheTTL
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIProviderError.authenticationFailed
        }

        return try await performMessageCompletionWithCaching(
            cachedContext: cachedContext,
            prompt: prompt,
            temperature: temperature,
            reasoningEffort: reasoningEffort,
            cacheTTL: cacheTTL
        )
    }

    private func performMessageCompletion(
        prompt: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort
    ) async throws -> String {
        let request = try requestBuilder.createRequest(
            prompt: prompt,
            temperature: temperature,
            stream: false,
            reasoningEffort: reasoningEffort
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.networkError(URLError(.badServerResponse))
        }

        try responseHandler.validateHTTPResponse(httpResponse, data: data)
        return try responseHandler.parseResponse(from: data)
    }

    private func performMessageCompletionWithCaching(
        cachedContext: String,
        prompt: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort,
        cacheTTL: CacheTTL
    ) async throws -> String {
        let request = try requestBuilder.createRequestWithCaching(
            cachedContext: cachedContext,
            prompt: prompt,
            temperature: temperature,
            stream: false,
            reasoningEffort: reasoningEffort,
            cacheTTL: cacheTTL
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.networkError(URLError(.badServerResponse))
        }

        try responseHandler.validateHTTPResponse(httpResponse, data: data)
        return try responseHandler.parseResponseWithCacheLogging(from: data)
    }

    private func performStreamingCompletion(
        prompt: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort
    ) async throws -> AsyncStream<String> {
        let request = try requestBuilder.createRequest(
            prompt: prompt,
            temperature: temperature,
            stream: true,
            reasoningEffort: reasoningEffort
        )

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.networkError(URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            throw try responseHandler.mapHTTPError(httpResponse.statusCode)
        }

        return AsyncStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        if let chunk = try self.responseHandler.parseStreamLine(line) {
                            continuation.yield(chunk)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }
}

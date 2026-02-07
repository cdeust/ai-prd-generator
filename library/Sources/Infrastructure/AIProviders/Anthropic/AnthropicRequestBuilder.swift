import Foundation
import AIPRDSharedUtilities

/// Builds URLRequest instances for Anthropic API calls
@available(iOS 15.0, macOS 12.0, *)
struct AnthropicRequestBuilder: Sendable {
    private let apiKey: String
    private let model: String
    private let baseURL: URL
    private let apiVersion: String
    private let maxOutputTokens: Int

    init(
        apiKey: String,
        model: String,
        baseURL: URL,
        apiVersion: String,
        maxOutputTokens: Int = 8192
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.apiVersion = apiVersion
        self.maxOutputTokens = maxOutputTokens
    }

    func createRequest(
        prompt: String,
        temperature: Double,
        stream: Bool,
        reasoningEffort: ReasoningEffort
    ) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("messages")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = AnthropicMessageRequest(
            model: model,
            messages: [AnthropicMessage(role: "user", content: prompt)],
            maxTokens: maxOutputTokens,
            temperature: temperature,
            stream: stream,
            thinking: AnthropicThinkingConfig.from(reasoningEffort: reasoningEffort)
        )

        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    func createRequestWithCaching(
        cachedContext: String,
        prompt: String,
        temperature: Double,
        stream: Bool,
        reasoningEffort: ReasoningEffort,
        cacheTTL: CacheTTL
    ) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("messages")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Set beta header for prompt caching (1-hour TTL requires extended-cache-ttl-2025-04-11)
        let betaHeader: String
        switch cacheTTL {
        case .default:
            betaHeader = "prompt-caching-2024-07-31"
        case .oneHour:
            betaHeader = "prompt-caching-2024-07-31,extended-cache-ttl-2025-04-11"
        }
        request.setValue(betaHeader, forHTTPHeaderField: "anthropic-beta")

        // Map CacheTTL to AnthropicCacheControl
        let cacheControl: AnthropicCacheControl
        switch cacheTTL {
        case .default:
            cacheControl = .ephemeral
        case .oneHour:
            cacheControl = .ephemeral1h
        }

        let message = AnthropicMessage(
            role: "user",
            contentBlocks: [
                AnthropicContentBlock(
                    text: cachedContext,
                    cacheControl: cacheControl
                ),
                AnthropicContentBlock(
                    text: prompt,
                    cacheControl: nil
                )
            ]
        )

        let body = AnthropicMessageRequest(
            model: model,
            messages: [message],
            maxTokens: maxOutputTokens,
            temperature: temperature,
            stream: stream,
            thinking: AnthropicThinkingConfig.from(reasoningEffort: reasoningEffort)
        )

        request.httpBody = try JSONEncoder().encode(body)
        return request
    }
}

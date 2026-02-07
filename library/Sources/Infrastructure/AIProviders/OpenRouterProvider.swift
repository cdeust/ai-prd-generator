import Foundation
import AIPRDSharedUtilities
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// OpenRouter AI Provider Implementation
/// Implements AIProviderPort using OpenRouter's unified API
/// Following Single Responsibility: Only handles OpenRouter API communication
/// Following naming convention: {Technology}Provider
///
/// OpenRouter provides unified access to 100+ models via OpenAI-compatible API
/// - API compatibility: 100% OpenAI-compatible (reuses OpenAI DTOs)
/// - Endpoint: https://openrouter.ai/api/v1
/// - Model naming: provider/model format (e.g., "anthropic/claude-sonnet-4-5")
/// - Optional features: HTTP-Referer and X-Title headers for dashboard tracking
@available(iOS 15.0, macOS 12.0, *)
public final class OpenRouterProvider: AIProviderPort, Sendable {
    // MARK: - Properties

    private let apiKey: String
    private let model: String
    private let baseURL: URL
    private let siteName: String?
    private let siteURL: String?

    // MARK: - Initialization

    /// Initialize OpenRouter provider
    /// - Parameters:
    ///   - apiKey: OpenRouter API key
    ///   - model: Model identifier (env: OPENROUTER_MODEL, default: anthropic/claude-sonnet-4-6)
    ///   - baseURL: API base URL (env: OPENROUTER_BASE_URL)
    ///   - siteName: Optional site name for dashboard tracking
    ///   - siteURL: Optional site URL for dashboard tracking
    public init(
        apiKey: String,
        model: String = "anthropic/claude-sonnet-4-6",
        baseURL: URL = URL(string: "https://openrouter.ai/api/v1")!,
        siteName: String? = nil,
        siteURL: String? = nil
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.siteName = siteName
        self.siteURL = siteURL
    }

    // MARK: - AIProviderPort Implementation

    public func generateText(
        prompt: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIProviderError.authenticationFailed
        }

        let response = try await performChatCompletion(
            prompt: prompt,
            temperature: temperature,
            reasoningEffort: reasoningEffort
        )

        return response
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

    public var providerName: String { "OpenRouter" }
    public var modelName: String { model }

    public var contextWindowSize: Int {
        // Parse context window from model name
        // Different models have different context windows
        if model.contains("claude-sonnet-4-5") || model.contains("claude-3-5-sonnet") {
            return 200_000  // Claude Sonnet: 200K tokens
        } else if model.contains("gpt-5") {
            return 200_000  // GPT-5.2: 200K tokens
        } else if model.contains("gpt-4") {
            return 128_000  // GPT-4: 128K tokens
        } else if model.contains("gpt-3.5-turbo") {
            return 16_385   // GPT-3.5 Turbo: 16K tokens
        } else if model.contains("gemini-3") {
            return 2_000_000  // Gemini 3.0: 2M tokens
        } else if model.contains("gemini") {
            return 128_000  // Older Gemini: 128K tokens
        }

        // Conservative default for unknown models
        return 32_000
    }

    // MARK: - Private Methods

    private func performChatCompletion(
        prompt: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort
    ) async throws -> String {
        let request = try createRequest(
            prompt: prompt,
            temperature: temperature,
            stream: false,
            reasoningEffort: reasoningEffort
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.networkError(URLError(.badServerResponse))
        }

        try validateHTTPResponse(httpResponse, data: data)

        // Reuse OpenAI response DTO (100% API compatible)
        let chatResponse = try JSONDecoder().decode(
            OpenAIChatCompletionResponse.self,
            from: data
        )

        guard let content = chatResponse.choices.first?.message.content else {
            throw AIProviderError.invalidResponse
        }

        return content
    }

    private func performStreamingCompletion(
        prompt: String,
        temperature: Double,
        reasoningEffort: ReasoningEffort
    ) async throws -> AsyncStream<String> {
        let request = try createRequest(
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
            let errorData = try? await bytes.reduce(into: Data()) { $0.append($1) }
            throw try mapHTTPError(httpResponse.statusCode, data: errorData)
        }

        return AsyncStream { continuation in
            Task {
                do {
                    for try await line in bytes.lines {
                        if let chunk = try parseStreamLine(line) {
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

    private func createRequest(
        prompt: String,
        temperature: Double,
        stream: Bool,
        reasoningEffort: ReasoningEffort
    ) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // OpenRouter-specific headers
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Optional: HTTP-Referer for dashboard tracking
        if let siteURL = siteURL {
            request.setValue(siteURL, forHTTPHeaderField: "HTTP-Referer")
        }

        // Optional: X-Title for dashboard tracking
        if let siteName = siteName {
            request.setValue(siteName, forHTTPHeaderField: "X-Title")
        }

        // Use OpenRouter request DTO with reasoning support
        // Map ReasoningEffort to OpenRouter reasoning config
        let reasoningConfig: OpenRouterReasoningConfig? = {
            switch reasoningEffort {
            case .none:
                return nil
            case .low:
                return OpenRouterReasoningConfig(enabled: true, maxTokens: 10_000)
            case .medium:
                return OpenRouterReasoningConfig(enabled: true, maxTokens: 25_000)
            case .high:
                return OpenRouterReasoningConfig(enabled: true, maxTokens: 50_000)
            }
        }()

        let body = OpenRouterChatCompletionRequest(
            model: model,
            messages: [["role": "user", "content": prompt]],
            maxTokens: nil,
            temperature: temperature,
            stream: stream,
            reasoning: reasoningConfig
        )

        request.httpBody = try JSONEncoder().encode(body)

        return request
    }

    private func parseStreamLine(_ line: String) throws -> String? {
        // OpenRouter uses same SSE format as OpenAI
        guard line.hasPrefix("data: ") else { return nil }

        let jsonString = String(line.dropFirst(6))
        guard jsonString != "[DONE]" else { return nil }

        // Reuse OpenAI stream chunk DTO (100% API compatible)
        let chunk = try JSONDecoder().decode(
            OpenAIStreamChunk.self,
            from: Data(jsonString.utf8)
        )

        return chunk.choices.first?.delta.content
    }

    private func validateHTTPResponse(
        _ httpResponse: HTTPURLResponse,
        data: Data
    ) throws {
        guard httpResponse.statusCode == 200 else {
            throw try mapHTTPError(httpResponse.statusCode, data: data)
        }
    }

    private func mapHTTPError(
        _ statusCode: Int,
        data: Data? = nil
    ) throws -> AIProviderError {
        switch statusCode {
        case 401:
            return .authenticationFailed
        case 429:
            return .rateLimited
        case 500...599:
            return .generationFailed("OpenRouter server error")
        default:
            if let data = data,
               let errorResponse = try? JSONDecoder().decode(
                OpenAIErrorResponse.self,
                from: data
               ) {
                return .generationFailed(errorResponse.error.message)
            }
            return .generationFailed("HTTP \(statusCode)")
        }
    }
}

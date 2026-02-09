import Foundation
import AIPRDSharedUtilities
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// OpenAI AI Provider Implementation
/// Implements AIProviderPort using OpenAI's Chat Completions API
/// Following Single Responsibility: Only handles OpenAI API communication
/// Following naming convention: {Technology}Provider
@available(iOS 15.0, macOS 12.0, *)
public final class OpenAIProvider: AIProviderPort, Sendable {
    // MARK: - Properties

    private let apiKey: String
    private let model: String
    private let baseURL: URL

    // MARK: - Initialization

    /// Initialize OpenAI provider
    /// - Parameters:
    ///   - apiKey: OpenAI API key
    ///   - model: Model identifier (env: OPENAI_MODEL, default: gpt-5.2)
    ///   - baseURL: API base URL (env: OPENAI_BASE_URL)
    public init(
        apiKey: String,
        model: String = "gpt-5.2",
        baseURL: URL = URL(string: "https://api.openai.com/v1")!
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
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

    public var providerName: String { "OpenAI" }
    public var modelName: String { model }
    public var contextWindowSize: Int {
        // GPT-5 preview has 200K context window
        if model.contains("gpt-5") { return 200_000 }
        // GPT-4o has 128K context window
        if model.contains("gpt-4") { return 128_000 }
        // GPT-3.5 has 16K context window
        return 16_000
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
            throw try mapHTTPError(httpResponse.statusCode)
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
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Map ReasoningEffort to OpenAI's reasoning_effort parameter
        // .none = no reasoning, others map directly to OpenAI's values
        let reasoningEffortValue: String? = reasoningEffort == .none ? nil : reasoningEffort.rawValue

        let body = OpenAIChatCompletionRequest(
            model: model,
            messages: [OpenAIChatMessage(role: "user", content: prompt)],
            maxTokens: nil,  // OpenAI: nil = generate until natural completion
            temperature: temperature,
            stream: stream,
            reasoningEffort: reasoningEffortValue
        )

        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func validateHTTPResponse(
        _ response: HTTPURLResponse,
        data: Data
    ) throws {
        guard response.statusCode == 200 else {
            throw try mapHTTPError(response.statusCode, data: data)
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
            return .generationFailed("OpenAI server error")
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

    private func parseStreamLine(_ line: String) throws -> String? {
        guard line.hasPrefix("data: ") else { return nil }
        let jsonString = String(line.dropFirst(6))
        guard jsonString != "[DONE]" else { return nil }

        let data = Data(jsonString.utf8)
        let chunk = try JSONDecoder().decode(
            OpenAIStreamChunk.self,
            from: data
        )

        return chunk.choices.first?.delta.content
    }
}

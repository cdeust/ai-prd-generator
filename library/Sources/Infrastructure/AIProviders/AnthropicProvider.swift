import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Domain

/// Anthropic AI Provider Implementation
/// Implements AIProviderPort using Anthropic's Messages API
/// Following Single Responsibility: Only handles Anthropic API communication
/// Following naming convention: {Technology}Provider
@available(iOS 15.0, macOS 12.0, *)
public final class AnthropicProvider: AIProviderPort, Sendable {
    // MARK: - Properties

    private let apiKey: String
    private let model: String
    private let baseURL: URL
    private let apiVersion: String

    // MARK: - Initialization

    public init(
        apiKey: String,
        model: String = "claude-sonnet-4-5-20250929",
        baseURL: URL = URL(string: "https://api.anthropic.com/v1")!,
        apiVersion: String = "2023-06-01"
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.apiVersion = apiVersion
    }

    // MARK: - AIProviderPort Implementation

    public func generateText(
        prompt: String,
        temperature: Double,
        extendedThinking: Bool? = true
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIProviderError.authenticationFailed
        }

        let response = try await performMessageCompletion(
            prompt: prompt,
            temperature: temperature,
            extendedThinking: extendedThinking ?? true
        )

        return response
    }

    public func streamText(
        prompt: String,
        temperature: Double,
        extendedThinking: Bool? = true
    ) async throws -> AsyncStream<String> {
        guard !apiKey.isEmpty else {
            throw AIProviderError.authenticationFailed
        }

        return try await performStreamingCompletion(
            prompt: prompt,
            temperature: temperature,
            extendedThinking: extendedThinking ?? true
        )
    }

    public var providerName: String { "Anthropic" }
    public var modelName: String { model }
    public var contextWindowSize: Int { 200_000 }  // Claude Sonnet 4.5: 200K

    // MARK: - Private Methods

    private func performMessageCompletion(
        prompt: String,
        temperature: Double,
        extendedThinking: Bool
    ) async throws -> String {
        let request = try createRequest(
            prompt: prompt,
            temperature: temperature,
            stream: false,
            extendedThinking: extendedThinking
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.networkError(URLError(.badServerResponse))
        }

        try validateHTTPResponse(httpResponse, data: data)

        let messageResponse = try JSONDecoder().decode(
            AnthropicMessageResponse.self,
            from: data
        )

        guard let content = messageResponse.content.first?.text else {
            throw AIProviderError.invalidResponse
        }

        return content
    }

    private func performStreamingCompletion(
        prompt: String,
        temperature: Double,
        extendedThinking: Bool
    ) async throws -> AsyncStream<String> {
        let request = try createRequest(
            prompt: prompt,
            temperature: temperature,
            stream: true,
            extendedThinking: extendedThinking
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
        extendedThinking: Bool
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
            maxTokens: 8192,  // Anthropic API requires this field (not optional) - using maximum reasonable value to avoid truncation
            temperature: temperature,
            stream: stream,
            thinking: extendedThinking ? .default : nil  // 50K token budget when enabled
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
            return .generationFailed("Anthropic server error")
        default:
            if let data = data,
               let errorResponse = try? JSONDecoder().decode(
                AnthropicErrorResponse.self,
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
            AnthropicStreamChunk.self,
            from: data
        )

        if chunk.type == "content_block_delta",
           let delta = chunk.delta {
            return delta.text
        }

        return nil
    }
}

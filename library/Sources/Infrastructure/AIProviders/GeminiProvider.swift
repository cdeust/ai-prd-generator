import Foundation
import AIPRDSharedUtilities
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Google Gemini AI Provider Implementation
/// Implements AIProviderPort using Google's Gemini API
/// Following Single Responsibility: Only handles Gemini API communication
/// Following naming convention: {Technology}Provider
@available(iOS 15.0, macOS 12.0, *)
public final class GeminiProvider: AIProviderPort, Sendable {
    // MARK: - Properties

    private let apiKey: String
    private let model: String
    private let baseURL: URL

    // MARK: - Initialization

    /// Initialize Gemini provider
    /// - Parameters:
    ///   - apiKey: Google API key
    ///   - model: Model identifier (env: GEMINI_MODEL, default: gemini-3.0-pro)
    ///   - baseURL: API base URL (env: GEMINI_BASE_URL)
    public init(
        apiKey: String,
        model: String = "gemini-3.0-pro",
        baseURL: URL = URL(string: "https://generativelanguage.googleapis.com/v1beta")!
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

        let response = try await performGenerateContent(
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

        return try await performStreamingContent(
            prompt: prompt,
            temperature: temperature,
            reasoningEffort: reasoningEffort
        )
    }

    public var providerName: String { "Gemini" }
    public var modelName: String { model }
    public var contextWindowSize: Int { 2_000_000 }  // Gemini 3.0 Pro: 2M tokens

    // MARK: - Private Methods

    private func performGenerateContent(
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

        let geminiResponse = try JSONDecoder().decode(
            GeminiGenerateContentResponse.self,
            from: data
        )

        guard let candidate = geminiResponse.candidates.first,
              let part = candidate.content.parts.first else {
            throw AIProviderError.invalidResponse
        }

        return part.text
    }

    private func performStreamingContent(
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
        let method = stream ? "streamGenerateContent" : "generateContent"
        var urlComponents = URLComponents(
            url: baseURL.appendingPathComponent("models/\(model):\(method)"),
            resolvingAgainstBaseURL: false
        )
        urlComponents?.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        guard let url = urlComponents?.url else {
            throw AIProviderError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = GeminiGenerateContentRequest(
            contents: [
                GeminiContent(
                    parts: [GeminiPart(text: prompt)]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                maxOutputTokens: nil,  // Omit to let model decide when to stop naturally
                temperature: temperature,
                thinkingLevel: mapReasoningEffortToThinkingLevel(reasoningEffort)
            )
        )

        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    /// Maps ReasoningEffort to Gemini's thinking_level parameter
    /// - `.none` = nil (no thinking)
    /// - `.low` = "LOW"
    /// - `.medium` = "MEDIUM"
    /// - `.high` = "HIGH"
    private func mapReasoningEffortToThinkingLevel(_ effort: ReasoningEffort) -> String? {
        switch effort {
        case .none:
            return nil
        case .low:
            return "LOW"
        case .medium:
            return "MEDIUM"
        case .high:
            return "HIGH"
        }
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
        case 400:
            return .authenticationFailed
        case 429:
            return .rateLimited
        case 500...599:
            return .generationFailed("Gemini server error")
        default:
            if let data = data,
               let errorResponse = try? JSONDecoder().decode(
                GeminiErrorResponse.self,
                from: data
               ) {
                return .generationFailed(errorResponse.error.message)
            }
            return .generationFailed("HTTP \(statusCode)")
        }
    }

    private func parseStreamLine(_ line: String) throws -> String? {
        guard !line.isEmpty else { return nil }

        let data = Data(line.utf8)
        let chunk = try JSONDecoder().decode(
            GeminiStreamChunk.self,
            from: data
        )

        guard let candidate = chunk.candidates.first,
              let part = candidate.content.parts.first else {
            return nil
        }

        return part.text
    }
}

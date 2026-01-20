import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Domain

/// Handles Anthropic Vision API communication
/// Separates network logic from analyzer orchestration
@available(iOS 15.0, macOS 12.0, *)
internal struct AnthropicAPIClient: Sendable {
    private let apiKey: String
    private let model: String
    private let baseURL: URL
    private let apiVersion: String
    private let retryPolicy: RetryPolicy

    internal init(
        apiKey: String,
        model: String,
        baseURL: URL,
        apiVersion: String,
        retryPolicy: RetryPolicy
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.apiVersion = apiVersion
        self.retryPolicy = retryPolicy
    }

    internal func callWithRetry(
        imageData: Data,
        prompt: String
    ) async throws -> String {
        var lastError: Error?

        for attempt in 0..<retryPolicy.maxAttempts {
            do {
                return try await call(imageData: imageData, prompt: prompt)
            } catch {
                lastError = error

                if retryPolicy.shouldRetry(attempt: attempt, error: error) {
                    let delay = retryPolicy.delay(for: attempt)
                    try await Task.sleep(
                        nanoseconds: UInt64(delay * 1_000_000_000)
                    )
                } else {
                    throw error
                }
            }
        }

        throw lastError ?? MockupAnalysisError.providerError("Max retries exceeded")
    }

    internal func call(
        imageData: Data,
        prompt: String
    ) async throws -> String {
        let request = try createRequest(imageData: imageData, prompt: prompt)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MockupAnalysisError.providerError("Invalid HTTP response")
        }

        guard httpResponse.statusCode == 200 else {
            throw mapHTTPError(httpResponse.statusCode, data: data)
        }

        let visionResponse = try JSONDecoder().decode(
            AnthropicVisionResponse.self,
            from: data
        )

        guard let content = visionResponse.content.first?.text else {
            throw MockupAnalysisError.providerError("No text content in response")
        }

        return content
    }

    private func createRequest(
        imageData: Data,
        prompt: String
    ) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("messages")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let imageBlock = AnthropicVisionImageBlock(
            imageData: imageData,
            mimeType: "image/png"
        )

        let body = AnthropicVisionRequest(
            model: model,
            messages: [
                AnthropicVisionMessage(
                    role: "user",
                    content: [
                        .image(imageBlock),
                        .text(prompt)
                    ]
                )
            ],
            maxTokens: 4096,
            temperature: 0.0
        )

        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func mapHTTPError(
        _ statusCode: Int,
        data: Data?
    ) -> MockupAnalysisError {
        switch statusCode {
        case 401:
            return .providerError("Authentication failed")
        case 429:
            return .providerError("Rate limit exceeded")
        case 500...599:
            return .providerError("Anthropic Vision server error")
        default:
            return .providerError("HTTP \(statusCode)")
        }
    }
}


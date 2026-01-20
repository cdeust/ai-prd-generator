import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Domain

/// Handles Google Gemini Vision API communication
/// Separates network logic from analyzer orchestration
@available(iOS 15.0, macOS 12.0, *)
internal struct GeminiAPIClient: Sendable {
    private let apiKey: String
    private let model: String
    private let baseURL: URL
    private let retryPolicy: RetryPolicy
    private let errorMapper: GeminiErrorMapper
    private let costTracker: CostTracker

    internal init(
        apiKey: String,
        model: String,
        baseURL: URL,
        retryPolicy: RetryPolicy,
        errorMapper: GeminiErrorMapper,
        costTracker: CostTracker
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.retryPolicy = retryPolicy
        self.errorMapper = errorMapper
        self.costTracker = costTracker
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

    private func call(
        imageData: Data,
        prompt: String
    ) async throws -> String {
        let request = try createRequest(imageData: imageData, prompt: prompt)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MockupAnalysisError.providerError("Invalid HTTP response")
        }

        guard httpResponse.statusCode == 200 else {
            throw errorMapper.mapHTTPError(
                statusCode: httpResponse.statusCode,
                data: data
            )
        }

        return try await parseResponse(data)
    }

    private func createRequest(
        imageData: Data,
        prompt: String
    ) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("models/\(model):generateContent")
            .appendingPathComponent("?key=\(apiKey)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let base64Image = imageData.base64EncodedString()
        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "image/png", "data": base64Image]]
                ]
            ]]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func parseResponse(_ data: Data) async throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw MockupAnalysisError.providerError("Invalid JSON response")
        }

        await trackUsage(from: json)

        guard let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw MockupAnalysisError.providerError("Invalid Gemini response structure")
        }

        return text
    }

    private func trackUsage(from json: [String: Any]) async {
        guard let usageMetadata = json["usageMetadata"] as? [String: Any],
              let promptTokenCount = usageMetadata["promptTokenCount"] as? Int,
              let candidatesTokenCount = usageMetadata["candidatesTokenCount"] as? Int else {
            return
        }

        await costTracker.recordUsage(
            provider: "gemini",
            inputTokens: promptTokenCount,
            outputTokens: candidatesTokenCount
        )
    }
}


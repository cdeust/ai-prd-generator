import Foundation
import Domain

/// Maps OpenAI API errors to domain errors
struct OpenAIErrorMapper: Sendable {
    func mapHTTPError(
        statusCode: Int,
        data: Data?
    ) -> MockupAnalysisError {
        switch statusCode {
        case 400:
            return .providerError("Invalid request to OpenAI")
        case 401:
            return .providerError("Invalid OpenAI API key")
        case 403:
            return .providerError("OpenAI API access forbidden")
        case 404:
            return .providerError("OpenAI endpoint not found")
        case 429:
            return parseRateLimitError(data: data)
        case 500:
            return .providerError("OpenAI server error")
        case 503:
            return .providerError("OpenAI service unavailable")
        default:
            return .providerError("OpenAI HTTP error \(statusCode)")
        }
    }

    func isRetryable(statusCode: Int) -> Bool {
        switch statusCode {
        case 429, 500, 502, 503, 504:
            return true
        default:
            return false
        }
    }

    private func parseRateLimitError(data: Data?) -> MockupAnalysisError {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any],
              let message = error["message"] as? String else {
            return .providerError("OpenAI rate limit exceeded")
        }

        return .providerError("Rate limit: \(message)")
    }
}


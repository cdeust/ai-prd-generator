import Foundation
import Domain

/// Maps Gemini API errors to domain errors
struct GeminiErrorMapper: Sendable {
    func mapHTTPError(
        statusCode: Int,
        data: Data?
    ) -> MockupAnalysisError {
        switch statusCode {
        case 400:
            return parseDetailedError(data: data) ?? .providerError("Invalid request to Gemini")
        case 401:
            return .providerError("Invalid Gemini API key")
        case 403:
            return .providerError("Gemini API access forbidden")
        case 404:
            return .providerError("Gemini model not found")
        case 429:
            return parseRateLimitError(data: data)
        case 500:
            return .providerError("Gemini server error")
        case 503:
            return .providerError("Gemini service unavailable")
        default:
            return .providerError("Gemini HTTP error \(statusCode)")
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
            return .providerError("Gemini rate limit exceeded")
        }

        return .providerError("Rate limit: \(message)")
    }

    private func parseDetailedError(data: Data?) -> MockupAnalysisError? {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any],
              let message = error["message"] as? String else {
            return nil
        }

        return .providerError("Gemini: \(message)")
    }
}


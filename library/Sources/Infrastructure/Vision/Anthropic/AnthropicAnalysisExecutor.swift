import Foundation
import Domain

/// Executes Anthropic Vision API calls with rate limiting and parsing
/// Separates execution concerns from result processing for testability
@available(iOS 15.0, macOS 12.0, *)
internal struct AnthropicAnalysisExecutor: Sendable {
    private let rateLimiter: RateLimiter
    private let jsonParser: AnthropicJSONParser
    private let validator: ResponseValidator

    internal init(
        rateLimiter: RateLimiter,
        jsonParser: AnthropicJSONParser,
        validator: ResponseValidator
    ) {
        self.rateLimiter = rateLimiter
        self.jsonParser = jsonParser
        self.validator = validator
    }

    internal func execute(
        apiCall: () async throws -> String
    ) async throws -> VisionAnalysisOutput {
        try await rateLimiter.waitForCapacity()
        let response = try await apiCall()
        return try parseWithValidation(response)
    }

    private func parseWithValidation(
        _ responseText: String
    ) throws -> VisionAnalysisOutput {
        let output = try jsonParser.parse(
            responseText,
            attempt: 0,
            maxAttempts: 3
        )

        try validator.validate(output)
        return output
    }
}


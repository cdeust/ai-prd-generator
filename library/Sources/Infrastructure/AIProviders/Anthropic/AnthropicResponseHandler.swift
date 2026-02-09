import Foundation
import AIPRDSharedUtilities

/// Handles Anthropic API response parsing and error mapping
@available(iOS 15.0, macOS 12.0, *)
struct AnthropicResponseHandler: Sendable {

    func validateHTTPResponse(
        _ response: HTTPURLResponse,
        data: Data
    ) throws {
        guard response.statusCode == 200 else {
            throw try mapHTTPError(response.statusCode, data: data)
        }
    }

    func mapHTTPError(
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

    func parseResponse(from data: Data) throws -> String {
        let messageResponse = try JSONDecoder().decode(
            AnthropicMessageResponse.self,
            from: data
        )

        guard let content = messageResponse.content.first?.text else {
            throw AIProviderError.invalidResponse
        }

        return content
    }

    func parseResponseWithCacheLogging(from data: Data) throws -> String {
        let messageResponse = try JSONDecoder().decode(
            AnthropicMessageResponse.self,
            from: data
        )

        logCacheUsage(messageResponse.usage)

        guard let content = messageResponse.content.first?.text else {
            throw AIProviderError.invalidResponse
        }

        return content
    }

    func parseStreamLine(_ line: String) throws -> String? {
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

    private func logCacheUsage(_ usage: AnthropicUsage?) {
        guard let usage = usage else { return }

        let cacheHitTokens = usage.cacheReadInputTokens ?? 0
        let cacheMissTokens = usage.cacheCreationInputTokens ?? 0

        if cacheHitTokens > 0 {
            print("💰 [Anthropic] Cache HIT: \(cacheHitTokens) tokens (90% cost reduction)")
        } else if cacheMissTokens > 0 {
            print("🔄 [Anthropic] Cache MISS: \(cacheMissTokens) tokens cached (5 min TTL)")
        }
    }
}
